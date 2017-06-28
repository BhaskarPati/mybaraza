CREATE TABLE Periods (
	Period_ID		serial primary key,
	Start_Date		date not null unique,
	End_Date		date not null,
	is_Active		boolean default true not null,
	Details			text
);

CREATE TABLE rates (
	rate_id			serial primary key,
	Period_ID		integer references Periods,
	rate_name		varchar(50),
	Currency		varchar(3),
	Fare			real,
	YR			real,
	YQ			real,
	KE			real,
	TU			real,
	SD			real,
	CD			real,
	Class			varchar(50),
	Class_Code		char(1),
	Fare_basis		varchar(70),
	Free_Baggage	real,
	Hand_Laguage	real,
	Excess_Baggage	real,
	Cancellation		real,
	one_way		boolean default false,
	one_way_rate		real default 0.5,
	child_fare		real default 0.5,
	infant_fare		real default 0.1,
	origin			char(3),
	destination		char(3),
	Details			text
);
CREATE INDEX rates_Period_ID ON rates (Period_ID);

CREATE TABLE headers (
	headerid		serial primary key,
	type			char(1),
	code			char(5),
	status			char(1),
	format			varchar(12),
	description		varchar(240),
	link_tail		char(5),
	rec_table		varchar(50)
);

CREATE TABLE elements (
	elementid		serial primary key,
	code			char(5),
	el				integer,
	format			char(1),
	description		varchar(50),
	glossary		char(4),
	status			varchar(12),
	element			varchar(12),
	pos				integer,
	fieldname		varchar(50)
);
	
CREATE TABLE BFH01 (
	FLD0			serial primary key,
	FLD1			varchar(120),
	FLD2			varchar(120),
	FLD3			varchar(120),
	FLD4			varchar(120),
	FLD5			varchar(120),
	FLD6			varchar(120),
	FLD7			varchar(120),
	FLD8			varchar(120),
	FLD9			varchar(120),
	FLD10			varchar(120),
	FLD11			varchar(120),
	FLD12			varchar(120),
	narrative		varchar(240),
	LNK				integer
);

CREATE TABLE BCH02 (
	FLD0			serial primary key,
	FLD1			varchar(120),
	FLD2			varchar(120),
	FLD3			varchar(120),
	FLD4			varchar(120),
	FLD5			varchar(120),
	FLD6			varchar(120),
	FLD7			varchar(120),
	FLD8			varchar(120),
	FLD9			varchar(120),
	narrative		varchar(240),
	LNK				integer
);

CREATE TABLE BOH03 (
	FLD0			serial primary key,
	FLD1			varchar(120),
	FLD2			varchar(120),
	FLD3			varchar(120),
	FLD4			varchar(120),
	FLD5			varchar(120),
	FLD6			varchar(120),
	FLD7			varchar(120),
	FLD8			varchar(120),
	FLD9			varchar(120),
	narrative		varchar(240),
	LNK				integer
);

CREATE TABLE BKT06 (
	FLD0			serial primary key,
	FLD1			varchar(120),
	FLD2			varchar(120),
	FLD3			varchar(120),
	FLD4			varchar(120),
	FLD5			varchar(120),
	FLD6			varchar(120),
	FLD7			varchar(120),
	FLD8			varchar(120),
	FLD9			varchar(120),
	FLD10			varchar(120),
	FLD11			varchar(120),
	FLD12			varchar(120),
	FLD13			varchar(120),
	FLD14			varchar(120),
	FLD15			varchar(120),
	FLD16			varchar(120),
	FLD17			varchar(120),
	FLD18			varchar(120),
	FLD19			varchar(120),
	FLD20			varchar(120),
	FLD21			varchar(120),
	FLD22			varchar(120),
	FLD23			varchar(120),
	FLD24			varchar(120),
	narrative		varchar(240),
	LNK				integer
);

CREATE TABLE BKS24 (
	FLD0			serial primary key,
	FLD1			varchar(120),
	FLD2			varchar(120),
	FLD3			varchar(120),
	FLD4			varchar(120),
	FLD5			varchar(120),
	FLD6			varchar(120),
	FLD7			varchar(120),
	FLD8			varchar(120),
	FLD9			varchar(120),
	FLD10			varchar(120),
	FLD11			varchar(120),
	FLD12			varchar(120),
	FLD13			varchar(120),
	FLD14			varchar(120),
	FLD15			varchar(120),
	FLD16			varchar(120),
	FLD17			varchar(120),
	FLD18			varchar(120),
	FLD19			varchar(120),
	narrative		varchar(240),
	LNK				integer
);

CREATE TABLE BKS30 (
	FLD0			serial primary key,
	FLD1			varchar(120),
	FLD2			varchar(120),
	FLD3			varchar(120),
	FLD4			varchar(120),
	FLD5			varchar(120),
	FLD6			varchar(120),
	FLD7			varchar(120),
	FLD8			varchar(120),
	FLD9			varchar(120),
	FLD10			varchar(120),
	FLD11			varchar(120),
	FLD12			varchar(120),
	FLD13			varchar(120),
	FLD14			varchar(120),
	FLD15			varchar(120),
	FLD16			varchar(120),
	FLD17			varchar(120),
	FLD18			varchar(120),
	FLD19			varchar(120),
	narrative		varchar(240),
	LNK				integer
);

CREATE TABLE BKS39 (
	FLD0			serial primary key,
	FLD1			varchar(120),
	FLD2			varchar(120),
	FLD3			varchar(120),
	FLD4			varchar(120),
	FLD5			varchar(120),
	FLD6			varchar(120),
	FLD7			varchar(120),
	FLD8			varchar(120),
	FLD9			varchar(120),
	FLD10			varchar(120),
	FLD11			varchar(120),
	FLD12			varchar(120),
	FLD13			varchar(120),
	FLD14			varchar(120),
	FLD15			varchar(120),
	FLD16			varchar(120),
	FLD17			varchar(120),
	FLD18			varchar(120),
	FLD19			varchar(120),
	FLD20			varchar(120),
	narrative		varchar(240),
	LNK				integer
);

CREATE TABLE BKS42 (
	FLD0			serial primary key,
	FLD1			varchar(120),
	FLD2			varchar(120),
	FLD3			varchar(120),
	FLD4			varchar(120),
	FLD5			varchar(120),
	FLD6			varchar(120),
	FLD7			varchar(120),
	FLD8			varchar(120),
	FLD9			varchar(120),
	FLD10			varchar(120),
	FLD11			varchar(120),
	FLD12			varchar(120),
	FLD13			varchar(120),
	FLD14			varchar(120),
	FLD15			varchar(120),
	FLD16			varchar(120),
	FLD17			varchar(120),
	FLD18			varchar(120),
	FLD19			varchar(120),
	FLD20			varchar(120),
	FLD21			varchar(120),
	FLD22			varchar(120),
	narrative		varchar(240),
	LNK				integer
);

CREATE TABLE BKS45 (
	FLD0			serial primary key,
	FLD1			varchar(120),
	FLD2			varchar(120),
	FLD3			varchar(120),
	FLD4			varchar(120),
	FLD5			varchar(120),
	FLD6			varchar(120),
	FLD7			varchar(120),
	FLD8			varchar(120),
	FLD9			varchar(120),
	FLD10			varchar(120),
	FLD11			varchar(120),
	FLD12			varchar(120),
	FLD13			varchar(120),
	FLD14			varchar(120),
	narrative		varchar(240),
	LNK				integer
);

CREATE TABLE BKS46 (
	FLD0			serial primary key,
	FLD1			varchar(120),
	FLD2			varchar(120),
	FLD3			varchar(120),
	FLD4			varchar(120),
	FLD5			varchar(120),
	FLD6			varchar(120),
	FLD7			varchar(120),
	FLD8			varchar(120),
	FLD9			varchar(120),
	FLD10			varchar(120),
	narrative		varchar(240),
	LNK				integer
);

CREATE TABLE BKI63 (
	FLD0			serial primary key,
	FLD1			varchar(120),
	FLD2			varchar(120),
	FLD3			varchar(120),
	FLD4			varchar(120),
	FLD5			varchar(120),
	FLD6			varchar(120),
	FLD7			varchar(120),
	FLD8			varchar(120),
	FLD9			varchar(120),
	FLD10			varchar(120),
	FLD11			varchar(120),
	FLD12			varchar(120),
	FLD13			varchar(120),
	FLD14			varchar(120),
	FLD15			varchar(120),
	FLD16			varchar(120),
	FLD17			varchar(120),
	FLD18			varchar(120),
	FLD19			varchar(120),
	FLD20			varchar(120),
	FLD21			varchar(120),
	FLD22			varchar(120),
	FLD23			varchar(120),
	FLD24			varchar(120),
	FLD25			varchar(120),
	FLD26			varchar(120),
	FLD27			varchar(120),
	FLD28			varchar(120),
	narrative		varchar(240),
	LNK				integer
);

CREATE TABLE BAR64 (
	FLD0			serial primary key,
	FLD1			varchar(120),
	FLD2			varchar(120),
	FLD3			varchar(120),
	FLD4			varchar(120),
	FLD5			varchar(120),
	FLD6			varchar(120),
	FLD7			varchar(120),
	FLD8			varchar(120),
	FLD9			varchar(120),
	FLD10			varchar(120),
	FLD11			varchar(120),
	FLD12			varchar(120),
	FLD13			varchar(120),
	FLD14			varchar(120),
	FLD15			varchar(120),
	FLD16			varchar(120),
	FLD17			varchar(120),
	FLD18			varchar(120),
	FLD19			varchar(120),
	FLD20			varchar(120),
	FLD21			varchar(120),
	FLD22			varchar(120),
	narrative		varchar(240),
	LNK				integer
);

CREATE TABLE BAR65 (
	FLD0			serial primary key,
	FLD1			varchar(120),
	FLD2			varchar(120),
	FLD3			varchar(120),
	FLD4			varchar(120),
	FLD5			varchar(120),
	FLD6			varchar(120),
	FLD7			varchar(120),
	FLD8			varchar(120),
	FLD9			varchar(120),
	narrative		varchar(240),
	LNK				integer
);

CREATE TABLE BAR66 (
	FLD0			serial primary key,
	FLD1			varchar(120),
	FLD2			varchar(120),
	FLD3			varchar(120),
	FLD4			varchar(120),
	FLD5			varchar(120),
	FLD6			varchar(120),
	FLD7			varchar(120),
	FLD8			varchar(120),
	FLD9			varchar(120),
	FLD10			varchar(120),
	narrative		varchar(240),
	LNK				integer
);

CREATE TABLE BMP70 (
	FLD0			serial primary key,
	FLD1			varchar(120),
	FLD2			varchar(120),
	FLD3			varchar(120),
	FLD4			varchar(120),
	FLD5			varchar(120),
	FLD6			varchar(120),
	FLD7			varchar(120),
	FLD8			varchar(120),
	FLD9			varchar(120),
	FLD10			varchar(120),
	narrative		varchar(240),
	LNK				integer
);

CREATE TABLE BMP71 (
	FLD0			serial primary key,
	FLD1			varchar(120),
	FLD2			varchar(120),
	FLD3			varchar(120),
	FLD4			varchar(120),
	FLD5			varchar(120),
	FLD6			varchar(120),
	FLD7			varchar(120),
	FLD8			varchar(120),
	FLD9			varchar(120),
	FLD10			varchar(120),
	FLD11			varchar(120),
	FLD12			varchar(120),
	FLD13			varchar(120),
	FLD14			varchar(120),
	FLD15			varchar(120),
	FLD16			varchar(120),
	narrative		varchar(240),
	LNK				integer
);

CREATE TABLE BMP72 (
	FLD0			serial primary key,
	FLD1			varchar(120),
	FLD2			varchar(120),
	FLD3			varchar(120),
	FLD4			varchar(120),
	FLD5			varchar(120),
	FLD6			varchar(120),
	FLD7			varchar(120),
	FLD8			varchar(120),
	FLD9			varchar(120),
	narrative		varchar(240),
	LNK				integer
);

CREATE TABLE BMP73 (
	FLD0			serial primary key,
	FLD1			varchar(120),
	FLD2			varchar(120),
	FLD3			varchar(120),
	FLD4			varchar(120),
	FLD5			varchar(120),
	FLD6			varchar(120),
	FLD7			varchar(120),
	FLD8			varchar(120),
	FLD9			varchar(120),
	narrative		varchar(240),
	LNK				integer
);

CREATE TABLE BMP74 (
	FLD0			serial primary key,
	FLD1			varchar(120),
	FLD2			varchar(120),
	FLD3			varchar(120),
	FLD4			varchar(120),
	FLD5			varchar(120),
	FLD6			varchar(120),
	FLD7			varchar(120),
	FLD8			varchar(120),
	FLD9			varchar(120),
	FLD10			varchar(120),
	narrative		varchar(240),
	LNK				integer
);

CREATE TABLE BMD75 (
	FLD0			serial primary key,
	FLD1			varchar(120),
	FLD2			varchar(120),
	FLD3			varchar(120),
	FLD4			varchar(120),
	FLD5			varchar(120),
	FLD6			varchar(120),
	FLD7			varchar(120),
	FLD8			varchar(120),
	FLD9			varchar(120),
	FLD10			varchar(120),
	FLD11			varchar(120),
	FLD12			varchar(120),
	FLD13			varchar(120),
	FLD14			varchar(120),
	FLD15			varchar(120),
	FLD16			varchar(120),
	FLD17			varchar(120),
	FLD18			varchar(120),
	FLD19			varchar(120),
	FLD20			varchar(120),
	narrative		varchar(240),
	LNK				integer
);

CREATE TABLE BMD76 (
	FLD0			serial primary key,
	FLD1			varchar(120),
	FLD2			varchar(120),
	FLD3			varchar(120),
	FLD4			varchar(120),
	FLD5			varchar(120),
	FLD6			varchar(120),
	FLD7			varchar(120),
	FLD8			varchar(120),
	FLD9			varchar(120),
	FLD10			varchar(120),
	narrative		varchar(240),
	LNK				integer
);

CREATE TABLE BMP77 (
	FLD0			serial primary key,
	FLD1			varchar(120),
	FLD2			varchar(120),
	FLD3			varchar(120),
	FLD4			varchar(120),
	FLD5			varchar(120),
	FLD6			varchar(120),
	FLD7			varchar(120),
	FLD8			varchar(120),
	FLD9			varchar(120),
	FLD10			varchar(120),
	FLD11			varchar(120),
	FLD12			varchar(120),
	narrative		varchar(240),
	LNK				integer
);

CREATE TABLE BMP78 (
	FLD0			serial primary key,
	FLD1			varchar(120),
	FLD2			varchar(120),
	FLD3			varchar(120),
	FLD4			varchar(120),
	FLD5			varchar(120),
	FLD6			varchar(120),
	FLD7			varchar(120),
	FLD8			varchar(120),
	FLD9			varchar(120),
	FLD10			varchar(120),
	FLD11			varchar(120),
	FLD12			varchar(120),
	narrative		varchar(240),
	LNK				integer
);

CREATE TABLE BKF81 (
	FLD0			serial primary key,
	FLD1			varchar(120),
	FLD2			varchar(120),
	FLD3			varchar(120),
	FLD4			varchar(120),
	FLD5			varchar(120),
	FLD6			varchar(120),
	FLD7			varchar(120),
	FLD8			varchar(120),
	FLD9			varchar(120),
	FLD10			varchar(120),
	FLD11			varchar(120),
	narrative		varchar(240),
	LNK				integer
);

CREATE TABLE BKP83 (
	FLD0			serial primary key,
	FLD1			varchar(120),
	FLD2			varchar(120),
	FLD3			varchar(120),
	FLD4			varchar(120),
	FLD5			varchar(120),
	FLD6			varchar(120),
	FLD7			varchar(120),
	narrative		varchar(240),
	LNK				integer
);

CREATE TABLE BKP84 (
	FLD0			serial primary key,
	FLD1			varchar(120),
	FLD2			varchar(120),
	FLD3			varchar(120),
	FLD4			varchar(120),
	FLD5			varchar(120),
	FLD6			varchar(120),
	FLD7			varchar(120),
	FLD8			varchar(120),
	FLD9			varchar(120),
	FLD10			varchar(120),
	FLD11			varchar(120),
	FLD12			varchar(120),
	FLD13			varchar(120),
	FLD14			varchar(120),
	FLD15			varchar(120),
	FLD16			varchar(120),
	FLD17			varchar(120),
	FLD18			varchar(120),
	FLD19			varchar(120),
	FLD20			varchar(120),
	narrative		varchar(240),
	LNK				integer
);

CREATE TABLE BOT93 (
	FLD0			serial primary key,
	FLD1			varchar(120),
	FLD2			varchar(120),
	FLD3			varchar(120),
	FLD4			varchar(120),
	FLD5			varchar(120),
	FLD6			varchar(120),
	FLD7			varchar(120),
	FLD8			varchar(120),
	FLD9			varchar(120),
	FLD10			varchar(120),
	FLD11			varchar(120),
	FLD12			varchar(120),
	FLD13			varchar(120),
	FLD14			varchar(120),
	FLD15			varchar(120),
	FLD16			varchar(120),
	narrative		varchar(240),
	LNK				integer
);

CREATE TABLE BOT94 (
	FLD0			serial primary key,
	FLD1			varchar(120),
	FLD2			varchar(120),
	FLD3			varchar(120),
	FLD4			varchar(120),
	FLD5			varchar(120),
	FLD6			varchar(120),
	FLD7			varchar(120),
	FLD8			varchar(120),
	FLD9			varchar(120),
	FLD10			varchar(120),
	FLD11			varchar(120),
	FLD12			varchar(120),
	FLD13			varchar(120),
	FLD14			varchar(120),
	FLD15			varchar(120),
	narrative		varchar(240),
	LNK				integer
);

CREATE TABLE BCT95 (
	FLD0			serial primary key,
	FLD1			varchar(120),
	FLD2			varchar(120),
	FLD3			varchar(120),
	FLD4			varchar(120),
	FLD5			varchar(120),
	FLD6			varchar(120),
	FLD7			varchar(120),
	FLD8			varchar(120),
	FLD9			varchar(120),
	FLD10			varchar(120),
	FLD11			varchar(120),
	FLD12			varchar(120),
	FLD13			varchar(120),
	FLD14			varchar(120),
	FLD15			varchar(120),
	FLD16			varchar(120),
	narrative		varchar(240),
	LNK				integer
);

CREATE TABLE BFT99 (
	FLD0			serial primary key,
	FLD1			varchar(120),
	FLD2			varchar(120),
	FLD3			varchar(120),
	FLD4			varchar(120),
	FLD5			varchar(120),
	FLD6			varchar(120),
	FLD7			varchar(120),
	FLD8			varchar(120),
	FLD9			varchar(120),
	FLD10			varchar(120),
	FLD11			varchar(120),
	FLD12			varchar(120),
	FLD13			varchar(120),
	FLD14			varchar(120),
	FLD15			varchar(120),
	narrative		varchar(240),
	LNK				integer
);

CREATE OR REPLACE FUNCTION amountFormat(varchar(16)) RETURNS double precision AS $$
    SELECT cast($1 as real)/10;
$$ LANGUAGE SQL;

CREATE VIEW vw_bks24 AS
	SELECT bks24.fld0, bks24.lnk, 
		bks24.fld2 as transaction_ref, to_date(bks24.fld4, 'YYMMDD') as ticket_date,
		bks24.fld6 as ticket_number, bks24.fld16 as segments, bks24.fld18 as agency_ref,
		bks24.fld15 as ticket_type, bks24.fld10 as ticket_usage, 
		amountFormat(bkp84.fld7) as amount, bkp84.fld19 as currency
	FROM bks24 LEFT JOIN bkp84 ON bks24.lnk = bkp84.lnk;


