CREATE TABLE pccs (
	pcc					varchar(4) primary key,
	agencyname			varchar(120),
	iata_agent			boolean default false not null,
	agency_incentive	boolean default false,
	incentive_son		varchar(12)
);

CREATE TABLE logs (
	logid			serial primary key,
	logdate			date,
	pcc				varchar(12),
	currency		varchar(12),
	processdate		date
);
CREATE INDEX logs_pcc ON logs (pcc);

CREATE TABLE logdetails (
	logid			integer references logs primary key,
	details			text
);

CREATE TABLE tickets (
	ticketid			varchar(25) primary key,
	ticketdate			date,
	ticketpcc			varchar(25),
	bookpcc				varchar(25),
	bpcc				varchar(12),
	son					varchar(4),
	pcc					varchar(12),
	line1				varchar(240),
	line2				varchar(240),
	line3				varchar(240),
	segs				integer default 0,
	TVOID				integer default 0,
	TOPEN				integer default 0,
	TUSED				integer default 0,
	TEXCH				integer default 0,
	TRFND				integer default 0,
	TARPT				integer default 0,
	TCKIN				integer default 0,
	TLFTD				integer default 0,
	TUNVL				integer default 0,
	TPRTD				integer default 0,
	TSUSP				integer default 0,
	
	for_incentive		boolean default false,
	incentive_updated	boolean default false,
	processed			boolean default false
);
CREATE INDEX tickets_pcc ON tickets (pcc);
CREATE INDEX tickets_bpcc ON tickets (bpcc);

CREATE TABLE tes (
	ticketid		varchar(25) references tickets primary key,
	details			text
);

CREATE TABLE Segments (
	SegmentID				serial primary key,
	YearMonth 				varchar(4),
   	City 					varchar(3),
   	ISO 					varchar(2),
   	PCC						varchar(4),
   	Agency					varchar(75),
   	NASegs					integer,
	NPSegs					integer,
	NFASegs					integer,
	NBBSegs					integer,
	NRSegs					integer,
	BCT						integer,
	AOTSegs					integer,
	PTSegs					integer,
	IsUploaded				boolean not null default false
);
CREATE INDEX Segments_pcc ON Segments (pcc);

CREATE TABLE 

CREATE VIEW vwlogs AS
	SELECT pccs.pcc, pccs.agencyname, logs.logid, logs.logdate, logs.currency, logs.processdate
	FROM pccs INNER JOIN logs ON pccs.pcc = logs.pcc;

CREATE VIEW vwtickets AS
	SELECT ticketid, ticketdate, ticketpcc, bookpcc,  pcc, bpcc, son,
		tvoid, topen, tused, texch, trfnd, tarpt, tckin, tlftd, tunvl, tprtd, tsusp,
		segs, (topen + tused + tarpt + tckin + tlftd + tprtd + tunvl) as activesegs,
		to_char(ticketdate, 'MMYYYY') as ticketperiod,
		(CAST(date_part('year', ticketdate) - 2000 as varchar) || to_char(ticketdate, 'MM')) as segperiod,
		to_char(ticketdate, 'Month') as ticketmonth,
		to_char(ticketdate, 'YYYY') as ticketyear
	FROM tickets;

CREATE VIEW vwticketsegs AS
	SELECT pccs.pcc, pccs.agencyname, vwtickets.ticketperiod, vwtickets.segperiod, 
		sum(vwtickets.activesegs) as totalsegs
	FROM (pccs INNER JOIN vwtickets ON pccs.pcc = vwtickets.pcc)
	GROUP BY pccs.pcc, pccs.agencyname, vwtickets.ticketperiod, vwtickets.segperiod;

CREATE VIEW vwdaysagencysegs AS
	SELECT pccs.pcc, pccs.agencyname, vwtickets.ticketperiod, vwtickets.segperiod, 
		vwtickets.ticketdate, sum(vwtickets.activesegs) as totalsegs
	FROM (pccs INNER JOIN vwtickets ON pccs.pcc = vwtickets.pcc)
	GROUP BY pccs.pcc, pccs.agencyname, vwtickets.ticketperiod, vwtickets.segperiod, vwtickets.ticketdate;

CREATE VIEW vwdayssegs AS
	SELECT vwtickets.ticketperiod, vwtickets.segperiod,  vwtickets.ticketdate, sum(vwtickets.activesegs) as totalsegs
	FROM vwtickets
	GROUP BY vwtickets.ticketperiod, vwtickets.segperiod, vwtickets.ticketdate;

CREATE VIEW vwbookedsegs AS
	SELECT pccs.pcc, pccs.agencyname, vwtickets.bookpcc, vwtickets.ticketperiod, vwtickets.segperiod, 
		sum(vwtickets.activesegs) as totalsegs
	FROM (pccs INNER JOIN vwtickets ON pccs.pcc = vwtickets.bpcc)
	GROUP BY pccs.pcc, pccs.agencyname, vwtickets.bookpcc, vwtickets.ticketperiod, vwtickets.segperiod;

CREATE VIEW vwsonsegs AS
	SELECT pccs.pcc, pccs.agencyname, vwtickets.bookpcc, vwtickets.son, vwtickets.ticketperiod, vwtickets.segperiod, 
		sum(vwtickets.activesegs) as totalsegs
	FROM (vwtickets LEFT JOIN pccs ON vwtickets.bpcc = pccs.pcc)
	GROUP BY pccs.pcc, pccs.agencyname, vwtickets.bookpcc, vwtickets.son, vwtickets.ticketperiod, vwtickets.segperiod;

CREATE VIEW vwsegements AS
	SELECT Segments.yearmonth, Segments.pcc as spcc, Segments.agency, 
		vwbookedsegs.pcc, vwbookedsegs.agencyname, vwbookedsegs.ticketperiod, 
		vwbookedsegs.segperiod, Segments.AOTSegs, vwbookedsegs.totalsegs,
		(Segments.AOTSegs - vwbookedsegs.totalsegs) as variance
	FROM Segments FULL JOIN vwbookedsegs ON
		(trim(upper(Segments.pcc)) = trim(upper(vwbookedsegs.pcc))) AND (trim(Segments.yearmonth) = vwbookedsegs.segperiod);

CREATE VIEW vwperiods AS
	SELECT ticketyear, ticketperiod, ticketmonth, segperiod, sum(vwtickets.activesegs) as totalsegs
	FROM vwtickets
	GROUP BY ticketyear, ticketperiod, ticketmonth, segperiod
	ORDER BY ticketyear, ticketperiod, segperiod;

CREATE VIEW vwperiodyears AS
	SELECT ticketyear 
	FROM vwtickets
	GROUP BY ticketyear
	ORDER BY ticketyear;

CREATE VIEW vwunallocated AS
	SELECT vwtickets.bpcc, vwtickets.ticketperiod, sum(vwtickets.activesegs) as segements
	FROM (vwtickets LEFT JOIN pccs ON vwtickets.bpcc = pccs.pcc)
	WHERE (pccs.pcc is null) AND (vwtickets.activesegs <> 0)
	GROUP BY vwtickets.bpcc, vwtickets.ticketperiod
	ORDER BY vwtickets.ticketperiod;


CREATE OR REPLACE FUNCTION ins_tickets() RETURNS trigger AS $$
DECLARE
	v_agency_incentive	boolean;
	v_incentive_son		varchar(12);
	v_pcc_son			varchar(12);
BEGIN

	IF((OLD.processed = false) AND (NEW.processed = true))THEN
	
		SELECT agency_incentive, incentive_son INTO v_agency_incentive, v_incentive_son
		FROM pccs WHERE pcc = NEW.bpcc;
		
		IF((NEW.for_incentive = false) AND (NEW.incentive_updated = false) AND (v_agency_incentive = true))THEN
			v_pcc_son := NEW.bpcc || v_incentive_son;
			
			INSERT INTO tickets(ticketid, 
				ticketdate, ticketpcc, bookpcc, bpcc, son, pcc, line1, 
				line2, line3, segs, tvoid, topen, tused, texch, trfnd, tarpt, 
				tckin, tlftd, tunvl, tprtd, tsusp, picked_time, for_incentive, 
				incentive_updated)
			VALUES('000' ||	substring(NEW.ticketid from 4 for 10), 
				current_date, NEW.bpcc, v_pcc_son, NEW.bpcc, v_incentive_son, NEW.bpcc, NEW.line1, 
				NEW.line2, NEW.line3, NEW.segs, NEW.tvoid, NEW.topen, NEW.tused, NEW.texch, NEW.trfnd, NEW.tarpt, 
				NEW.tckin, NEW.tlftd, NEW.tunvl, NEW.tprtd, NEW.tsusp, NEW.picked_time, true, true);
				
			NEW.incentive_updated = true;
		END IF;
	END IF;
	
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ins_tickets BEFORE UPDATE ON tickets
    FOR EACH ROW EXECUTE PROCEDURE ins_tickets();


