---------------------------------------------------- helpdesk

CREATE FUNCTION getWorkHours(timestamp, timestamp) RETURNS float AS $$
DECLARE
	startdate date;
	lastdate date;
	fordays integer;
	curtime timestamp;

	workdays float := 0;
	dayhours float;
	workhours float;

	i integer;
BEGIN
	if($1 is null) then
		startdate := current_date;
	else
		startdate := $1;
	end if;

	if($2 is null) then
		lastdate := current_date;
	else
		lastdate := $2;
	end if;

	fordays := lastdate - startdate - 2;

	if($1 is null) then
		curtime := localtimestamp;
	else
		curtime := $1;
	end if;

	if (extract(dow from curtime)=6) then
		dayhours := 13 - (extract(hour from curtime) + extract(minute from curtime)/60);
	else
		dayhours := 17 - (extract(hour from curtime) + extract(minute from curtime)/60);
	end if;

	if (dayhours<0) then
		dayhours := 0;
	elseif (extract(dow from curtime)=6) and (dayhours>5) then
		dayhours := 5;
	elseif (extract(dow from curtime)>0) and (dayhours>9) then
		dayhours := 9;
	elseif (extract(dow from curtime)=0) then
		dayhours := 0;
	end if;
	workhours := dayhours;

	for i in 0..fordays loop
		curtime := curtime + interval '1 day';

		if (extract(dow from curtime)=6) then
			workdays := workdays + 0.5;
		elseif (extract(dow from curtime)>0) then
			workdays := workdays + 1;
		end if;
	end loop;

	if($2 is null) then
		curtime := localtimestamp;
	else
		curtime := $2;
	end if;

	dayhours := (extract(hour from curtime) + extract(minute from curtime)/60) - 8;

	if (dayhours<0) then
		dayhours := 0;
	elseif (extract(dow from curtime)=6) and (dayhours>5) then
		dayhours := 5;
	elseif (extract(dow from curtime)>0) and (dayhours>9) then
		dayhours := 9;
	elseif (extract(dow from curtime)=0) then
		dayhours := 0;
	end if;

	workhours := workhours + dayhours;
	workhours := workhours + (workdays * 9);

	if (startdate = lastdate) then
		if (extract(dow from curtime)=6) then
			workhours := workhours - 5;
		elseif (extract(dow from curtime)>0) then
			workhours := workhours - 9;
		end if;
		if (workhours<0) then
			workhours := 0;
		end if;
	end if;

	RETURN workhours;
END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION getDependent(integer) RETURNS boolean AS $$
DECLARE
	isDependent boolean := false;
	myrec RECORD;
	myview RECORD;
BEGIN
	SELECT INTO myrec * FROM forwarded WHERE forwardid = $1;

	FOR myview IN SELECT * FROM forwarded WHERE (problemlogid = myrec.problemlogid) and (stageorder < myrec.stageorder) LOOP
		IF (myview.issolved = false) THEN
			isDependent := true;
		END IF;
	END LOOP;

	IF (myrec.isDependent=false) THEN
		isDependent := false;
	END IF;
			
	RETURN isDependent;
END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION getLastTime(integer) RETURNS TimeStamp AS $$
DECLARE
	lasttime TimeStamp;
	mystageorder integer;
	isDependent boolean;
	myrec RECORD;
	myview RECORD;
BEGIN
	SELECT INTO myrec * FROM forwarded WHERE forwardid = $1;
	mystageorder := myrec.stageorder - 1;
	isDependent := getDependent($1);

	SELECT INTO myview * FROM forwarded WHERE (problemlogid=myrec.problemlogid) and (stageorder=mystageorder) ORDER BY SolvedTime;
	IF NOT FOUND THEN
		lasttime := myrec.ForwardTime;
	ELSEIF myview.SolvedTime is null THEN
		lasttime := localtimestamp;
		IF isDependent = false THEN
			lasttime := myview.ForwardTime;
		END IF;
	ELSE
		lasttime := myview.SolvedTime;
	END IF;
			
	RETURN lasttime;
END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION getProblemDrop(integer) RETURNS bigint AS $$
	SELECT count(ForwardID)
	FROM Forwarded 
	WHERE (ProblemLogID = $1) AND (IsDrop = true);
$$ LANGUAGE SQL;

CREATE FUNCTION getProblemOpen(integer) RETURNS bigint AS $$
	SELECT count(ForwardID)
	FROM Forwarded 
	WHERE (ProblemLogID = $1) AND (IsSolved = false);
$$ LANGUAGE SQL;


CREATE FUNCTION getCountERF(integer) RETURNS bigint AS $$
	SELECT count(ERFID)
	FROM ERF
	WHERE ProblemLogID = $1;
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION ins_ProblemLog() RETURNS trigger AS $$
BEGIN
	
	NEW.entity_id := NEW.updated_by;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ins_ProblemLog BEFORE INSERT ON ProblemLog
    FOR EACH ROW EXECUTE PROCEDURE ins_ProblemLog();

CREATE OR REPLACE FUNCTION upd_ProblemLog() RETURNS trigger AS $$
BEGIN
	-- Check that forward is closed
	IF (OLD.IsSolved=false) and (NEW.IsSolved = True) THEN
		NEW.SolvedTime := now();
		NEW.Closed_By := NEW.updated_by;
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER upd_ProblemLog BEFORE UPDATE ON ProblemLog
    FOR EACH ROW EXECUTE PROCEDURE upd_ProblemLog();

CREATE OR REPLACE FUNCTION aft_ProblemLog() RETURNS TRIGGER AS $$
DECLARE
    myrecord RECORD;
BEGIN
	
	INSERT INTO Forwarded (ProblemLogID, entity_id, Description, StageOrder, isDependent, isDelayedAction, TimeInterval, SystemForward, IsForApproval)
	SELECT NEW.ProblemLogID, entity_id, task, StageOrder, isDependent,
			isDelayedAction, TimeInterval, true, IsForApproval
	FROM Stages 
	WHERE Stages.PDefinitionID = NEW.PDefinitionID;
	
	RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER aft_ProblemLog AFTER INSERT ON ProblemLog
    FOR EACH ROW EXECUTE PROCEDURE aft_ProblemLog();

CREATE OR REPLACE FUNCTION ins_Forward() RETURNS trigger AS $$
BEGIN
	NEW.sender_id := NEW.updated_by;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ins_Forward BEFORE INSERT ON Forwarded
    FOR EACH ROW EXECUTE PROCEDURE ins_Forward();
    
CREATE OR REPLACE FUNCTION upd_Forward() RETURNS trigger AS $$
BEGIN
	-- Check that forward is closed
	IF (OLD.IsSolved=false) and (NEW.IsSolved = True) THEN
		NEW.SolvedTime = now();
	END IF;

	RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER upd_Forward BEFORE UPDATE ON Forwarded
    FOR EACH ROW EXECUTE PROCEDURE upd_Forward();

CREATE FUNCTION updEscalation(integer) RETURNS timestamp AS $$
    UPDATE Forwarded SET LastEscalation = now() WHERE ForwardID = $1;
    SELECT LastEscalation FROM Forwarded WHERE ForwardID = $1;
$$ LANGUAGE SQL;

CREATE FUNCTION updCloseForwarded(text, integer) RETURNS varchar(250) AS $$
	UPDATE Forwarded SET whatisdone=$1, SolvedTime=now(), IsSolved=true WHERE Forwardid=$2;
	SELECT varchar 'Escalated Problem Ticket is closed' as myreply;
$$ LANGUAGE SQL;

CREATE FUNCTION updDropForwarded(text, integer) RETURNS varchar(250) AS $$
	UPDATE Forwarded SET whatisdone=$1, SolvedTime=now(), IsDrop = true WHERE Forwardid=$2;
	SELECT varchar 'Escalated Problem Ticket is Droppped' as myreply;
$$ LANGUAGE SQL;

----------------------------------------------- Field Support

CREATE FUNCTION getcaravailable(integer, date, time, time) RETURNS bigint AS $$
	SELECT count(transportid) 
	FROM Transport
	WHERE (carid = $1) AND (TransportDate = $2)
	AND (((booktime, ReturnTime) OVERLAPS ($3, $4))=true)
 	AND (IsApproved=true);
$$ LANGUAGE SQL;

CREATE FUNCTION getcarbooked(integer, date, time, time) RETURNS varchar(50) AS $$
	SELECT max(entitys.entity_name) 
	FROM transport INNER JOIN entitys ON transport.entity_id = entitys.entity_id
	WHERE (transport.carid = $1) AND (transport.transportDate = $2)
	AND (((transport.booktime, transport.returntime) OVERLAPS ($3, $4))=true);
$$ LANGUAGE SQL;

---------------------------------------- Assets

CREATE FUNCTION getClientAsset(integer) RETURNS bigint AS $$
	SELECT count(assetid) FROM ClientAssets 
	WHERE (assetid = $1) AND (IsIssued = true) AND (IsRetrived = false);
$$ LANGUAGE SQL;

CREATE FUNCTION getClientCPU(integer, date) RETURNS bigint AS $$
	SELECT count(Assets.assetsn) FROM ClientAssets INNER JOIN Assets ON ClientAssets.Assetid = Assets.Assetid
	WHERE (ClientAssets.clientid = $1) AND (Assets.assetsubtypeid = 1) AND (ClientAssets.IsIssued = true)
		AND (ClientAssets.dateIssued <= $2+14)
		AND ((ClientAssets.dateRetrived IS NULL) OR (ClientAssets.dateRetrived >= $2+14));
$$ LANGUAGE SQL;

CREATE FUNCTION getClientCPU(integer) RETURNS bigint AS $$
	SELECT count(Assets.assetsn) FROM ClientAssets INNER JOIN Assets ON ClientAssets.Assetid = Assets.Assetid
	WHERE (ClientAssets.clientid = $1) AND (Assets.assetsubtypeid = 1) AND (ClientAssets.IsIssued = true)
		AND (ClientAssets.isretrived = false);
$$ LANGUAGE SQL;

CREATE FUNCTION getClientInternet(integer) RETURNS varchar(50) AS $$
	SELECT max(AssetSubTypes.AssetSubTypeName) 
	FROM (ClientAssets INNER JOIN Assets ON ClientAssets.Assetid = Assets.Assetid)
		INNER JOIN AssetSubTypes ON Assets.AssetSubTypeid = AssetSubTypes.AssetSubTypeid
	WHERE (ClientAssets.clientid = $1) AND (AssetSubTypes.assettypeid = 10) AND (ClientAssets.IsIssued = true)
		AND (ClientAssets.isretrived = false);
$$ LANGUAGE SQL;
	
--------------------------------- Accounts
CREATE FUNCTION getkqquarter(timestamp) RETURNS integer AS $$
DECLARE
	kqquarter integer := 0;
BEGIN
	kqquarter := trunc((date_part('month', $1)-1)/3);
	if (kqquarter=0) then
		kqquarter := 4;
	end if;
			
	RETURN kqquarter;
END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION getPrevPeriod(date) RETURNS integer AS $$
	SELECT max(periodid) FROM periods 
	WHERE (extract(year from startdate) = (extract(year from $1)-1)) 
		AND (extract(month from startdate) = extract(month from $1));
$$ LANGUAGE SQL;

CREATE FUNCTION insPeriodAssetCosts() RETURNS TRIGGER AS $$
BEGIN
	INSERT INTO PeriodAssetCosts (AssetSubTypeID, PeriodID, ClientCost, segments)
	SELECT AssetSubTypeID, NEW.PeriodID, ClientCost, segments
	FROM AssetSubTypes;
	
	RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER insPeriodAssetCosts AFTER INSERT ON periods
    FOR EACH ROW EXECUTE PROCEDURE insPeriodAssetCosts();

CREATE FUNCTION getClientCost(integer, integer, date) RETURNS float AS $$
DECLARE
	clientcost float;
	myrec RECORD;
BEGIN
	SELECT INTO myrec sum(periodassetcosts.segments * ClientAssets.units) as sumsegments
		FROM ((periodassetcosts INNER JOIN Assets ON periodassetcosts.AssetSubTypeID = Assets.AssetSubTypeID) 
			INNER JOIN ClientAssets ON ClientAssets.Assetid = Assets.Assetid) 
		WHERE (ClientAssets.clientid = $1) AND (periodassetcosts.periodid = $2) AND (ClientAssets.IsIssued = true) 
		AND (ClientAssets.dateIssued <= $3 + 14) 
		AND ((ClientAssets.dateRetrived IS NULL) OR (ClientAssets.dateRetrived >= $3 + 14));

	clientcost := myrec.sumsegments;
	IF (clientcost is null) THEN
		clientcost := 0;
	END IF;
			
	RETURN clientcost;
END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION getsegs(int, int, varchar(2)) RETURNS real AS $$
	SELECT CASE WHEN sum(prd) is null THEN 0 ELSE sum(prd) END
	FROM MIDTTransactions WHERE (ClientID = $1) AND (PeriodID = $2) AND (CRS = $3);
$$ LANGUAGE SQL;

CREATE FUNCTION getPrevSegs(int, int) RETURNS bigint AS $$
	SELECT sum(nasegs) 
	FROM Transactions
	WHERE (clientid = $1) AND (PeriodID = $2);
$$ LANGUAGE SQL;

CREATE FUNCTION getYTD(integer, varchar(12), date) RETURNS bigint AS $$
	SELECT sum(NASegs) FROM Transactions INNER JOIN Periods ON Transactions.Periodid = Periods.Periodid
	WHERE (Transactions.clientid = $1) AND (Periods.AccountPeriod = $2) AND (Periods.Startdate <= $3);
$$ LANGUAGE SQL;

CREATE FUNCTION getYTD(integer, date) RETURNS bigint AS $$
	SELECT sum(NASegs) FROM Transactions INNER JOIN Periods ON Transactions.Periodid = Periods.Periodid
	WHERE (Transactions.clientid = $1) AND EXTRACT(YEAR FROM Periods.Startdate) = EXTRACT(YEAR FROM $2) AND (Periods.Startdate <= $2);
$$ LANGUAGE SQL;

CREATE FUNCTION getMIDTYTD(varchar(12), date) RETURNS real AS $$
	SELECT sum(MIDTTransactions.prd) FROM MIDTTransactions INNER JOIN Periods ON MIDTTransactions.Periodid = Periods.Periodid
	WHERE (MIDTTransactions.pcc = $1) AND EXTRACT(YEAR FROM Periods.Startdate) = EXTRACT(YEAR FROM $2) AND (Periods.Startdate <= $2);
$$ LANGUAGE SQL;

CREATE FUNCTION getgkmonthyear(date) RETURNS varchar(4) AS $$
	SELECT to_char($1, 'yy') || to_char($1, 'mm');
$$ LANGUAGE SQL;

CREATE FUNCTION getperiodid(varchar(4)) RETURNS integer AS $$
	SELECT periodid FROM periods WHERE (getgkmonthyear(startdate)=lpad($1, 4, '0'));
$$ LANGUAGE SQL;

CREATE FUNCTION getclientid(varchar(12), varchar(2)) RETURNS integer AS $$
	SELECT clientid FROM pccs WHERE (pcc = upper(trim($1))) AND (gds = upper(trim($2)));
$$ LANGUAGE SQL;

CREATE FUNCTION getTransactionid(integer, integer) RETURNS integer AS $$
	SELECT Transactionid FROM Transactions WHERE (clientid=$1) AND (periodid=$2);
$$ LANGUAGE SQL;

CREATE FUNCTION getIATAclientid(varchar(12)) RETURNS integer AS $$
	SELECT clientid FROM clients WHERE (substring(iatano from 1 for 7) = upper(trim($1)));
$$ LANGUAGE SQL;

CREATE FUNCTION insTransactions() RETURNS varchar(50) AS $$
BEGIN
	INSERT INTO Transactions (PeriodID, ClientID, PCC, UserID, Productivity, NPSegs, NASegs, NFASegs, NBBSegs, NRSegs, BCT, AOTSegs, PTSegs)
	SELECT periods.periodid, getclientid(upper(trim(pcc)), 'G'), upper(trim(pcc)), getAccountManager(getclientid(upper(trim(pcc)), 'G')),
		cast(NAAB as int), cast(NPAB as int), 0, 0, 0, 0, 0, 0, 0
	FROM new_Segments INNER JOIN periods ON new_Segments.month_year = to_char(periods.startdate, 'MMYY')
	WHERE (periods.periodid is not null) AND (getclientid(upper(trim(pcc)), 'G') is not null);

	INSERT INTO Transactions (PeriodID, ClientID, UserID, Productivity, NPSegs, NFASegs, NBBSegs, NRSegs, BCT, AOTSegs, PTSegs, NASegs)
	(SELECT periods.periodid, clients.clientid, getAccountManager(clients.clientid), 0, 0, 0, 0, 0, 0, 0, 0, 0
	FROM periods CROSS JOIN clients
	WHERE (periods.startdate > '2008-12-30') AND (clients.IsActive = true))
	EXCEPT
	(SELECT Transactions.periodid, Transactions.clientid, getAccountManager(Transactions.clientid), 0, 0, 0, 0, 0, 0, 0, 0, 0
	FROM Transactions);

	DELETE FROM new_Segments USING periods
	WHERE month_year = to_char(periods.startdate, 'MMYY')
	AND (getclientid(upper(trim(pcc)), 'G') is not null);
	
	RETURN 'Done';
END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION insCompetitionTransactions() RETURNS varchar(50) AS $$
DECLARE
    myrecord RECORD;
	myperiodid integer;
	myclientid integer;
	mytransid integer;
BEGIN
	UPDATE MIDTSegments SET CRS = 'G' WHERE trim(CRS) = '1G';
	UPDATE MIDTSegments SET CRS = 'G' WHERE trim(CRS) = 'IG';
	UPDATE MIDTSegments SET CRS = 'M' WHERE trim(CRS) = '1A';
	UPDATE MIDTSegments SET CRS = 'S' WHERE trim(CRS) = '1S';

	FOR myrecord IN SELECT MIDTSegmentID, cast(YearMonth as varchar) as YearMonth, CRS, trim(split_part(pcc, ' ', 1)) as PCC, Agency, IATANo, cast(prd as int) as prd, Downloaddate
	FROM MIDTSegments WHERE IsUploaded = False LOOP
		myperiodid = getperiodid(myrecord.YearMonth);
		IF(upper(myrecord.CRS) = 'M') THEN
			IF(getIATAclientid(myrecord.IATANo) is null) THEN
				myclientid = getclientid(myrecord.PCC, upper(myrecord.CRS));
			ELSE
				myclientid = getIATAclientid(myrecord.IATANo);
			END IF;
		ELSE
			myclientid = getclientid(myrecord.PCC, upper(myrecord.CRS));
		END IF;
		
		INSERT INTO MIDTTransactions (ClientID, PeriodID, CRS, PCC, Agency, prd, IATANo)
		VALUES (myclientid, myperiodid, myrecord.CRS, myrecord.PCC, myrecord.Agency, myrecord.prd, myrecord.IATANo);
		UPDATE MIDTSegments SET IsUploaded = true WHERE MIDTSegmentID = myrecord.MIDTSegmentID;

		IF(upper(myrecord.CRS) = 'G') THEN
			UPDATE Transactions SET NASegs = myrecord.prd
			WHERE (ClientID = myclientid) AND (PeriodID = myperiodid) AND (pcc = myrecord.PCC);
		END IF;
	END LOOP;

	INSERT INTO Transactions (PeriodID, ClientID, UserID, Productivity, NPSegs, NFASegs, NBBSegs, NRSegs, BCT, AOTSegs, PTSegs, NASegs)
	(SELECT periods.periodid, clients.clientid, getAccountManager(clients.clientid), 0, 0, 0, 0, 0, 0, 0, 0, 0
	FROM periods CROSS JOIN clients
	WHERE (periods.startdate > '2009-12-30') AND (clients.IsActive = true))
	EXCEPT
	(SELECT Transactions.periodid, Transactions.clientid, getAccountManager(Transactions.clientid), 0, 0, 0, 0, 0, 0, 0, 0, 0
	FROM Transactions);

	UPDATE MIDTTransactions SET clientid = pccs.clientid
	FROM pccs WHERE (MIDTTransactions.pcc = pccs.pcc) AND (MIDTTransactions.clientid is null);

	DELETE FROM MIDTSegments WHERE IsUploaded = true;
	
	RETURN 'Done';
END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION insConsultantTransactions() RETURNS varchar(50) AS $$
DECLARE
    myrecord RECORD;
	myperiodid integer;
	myclientid integer;
BEGIN
	
	FOR myrecord IN SELECT * FROM ConsultantSegments WHERE ConsultantSegments.IsUploaded = False LOOP
		myperiodid = getperiodid(myrecord.YearMonth);
		myclientid = getclientid(myrecord.PCC, 'G');

		IF (myperiodid is not null) and (myclientid is not null) THEN
			INSERT INTO ConsultantTransactions (ClientID, PeriodID, PCC, SON, prd1, prd2, prd3)
			VALUES (myclientid, myperiodid, myrecord.PCC, myrecord.SON, myrecord.prd1, myrecord.prd2, myrecord.prd3);

			UPDATE ConsultantSegments SET IsUploaded = true WHERE ConsultantSegmentID = myrecord.ConsultantSegmentID;
		END IF;
	END LOOP;

	DELETE FROM ConsultantSegments WHERE IsUploaded = true;
	
	RETURN 'Done';
END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION insTicketedTransactions() RETURNS varchar(50) AS $$
DECLARE
    myrecord RECORD;
	myperiodid integer;
	myclientid integer;
	mytransid integer;
BEGIN
	
	FOR myrecord IN SELECT * FROM TKPSegments WHERE IsUploaded = False LOOP
		myperiodid = getperiodid(substr(myrecord.RYear, 3, 2) || myrecord.RMonth);
		myclientid = getclientid(trim(myrecord.PCC));
		mytransid = getTransactionid(myclientid, myperiodid);

		IF (mytransid is not null) THEN
			UPDATE Transactions SET eticket = myrecord.prd1, pticket = myrecord.prd5 WHERE TransactionID = mytransid;
			UPDATE TKPSegments SET IsUploaded = true WHERE TKPSegmentID = myrecord.TKPSegmentID;
		END IF;
	END LOOP;

	DELETE FROM TKPSegments WHERE IsUploaded = true;
	
	RETURN 'Done';
END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION getnegseg(integer, integer) RETURNS bigint AS $$    
	SELECT sum(prd3) FROM ConsultantTransactions 
	WHERE (ClientID = $1) AND (PeriodID = $2) AND (prd3<0);
$$ LANGUAGE SQL;

CREATE FUNCTION getairseg(integer, integer) RETURNS bigint AS $$
	SELECT sum(prd3) FROM ConsultantTransactions 
	WHERE (ClientID = $1) AND (PeriodID = $2) AND (son = '%%');
$$ LANGUAGE SQL;

CREATE FUNCTION getnaseg(integer, integer) RETURNS bigint AS $$
	SELECT sum(nasegs) FROM Transactions 
	WHERE (ClientID = $1) AND (PeriodID = $2);
$$ LANGUAGE SQL;

CREATE FUNCTION gettkpseg(integer, integer) RETURNS bigint AS $$
	SELECT sum(AOTSegs) FROM Transactions 
	WHERE (ClientID = $1) AND (PeriodID = $2);
$$ LANGUAGE SQL;

CREATE FUNCTION getdistribution(integer) RETURNS float AS $$
DECLARE
	myrec RECORD;
	negseg real;
	airseg real;
	naseg real;
	base real;
	ratio real;
	distvalue real;
BEGIN
	SELECT INTO myrec * FROM ConsultantTransactions WHERE ConsultantTransactionID = $1;
	negseg := getnegseg(myrec.clientid, myrec.periodid);
	if (negseg is null) then negseg := 0; end if;
	airseg := getairseg(myrec.clientid, myrec.periodid);
	if (airseg is null) then airseg := 0; end if;
	naseg := getnaseg(myrec.clientid, myrec.periodid);
	if (naseg is null) then naseg := 0; end if;

	if (airseg<0) then
		negseg := negseg - airseg;
	end if;
	base := naseg - airseg - (negseg * 2);

	ratio := 0;
	if (base <> 0) then
		ratio := abs(airseg * myrec.prd3 / base);
	end if;
	if (airseg<0) then
		ratio := ratio * (-1);          
	end if;

	distvalue := 0;
	if (myrec.son <> '%%') then
		distvalue := (myrec.prd3 + ratio);
	end if;

	RETURN distvalue;
END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION gettkpdistribution(integer) RETURNS float AS $$
DECLARE
	myrec RECORD;
	consseg real;   
	naseg real;
	tkpseg real;
	distvalue real;
BEGIN
	SELECT INTO myrec * FROM ConsultantTransactions WHERE ConsultantTransactionID = $1;

	consseg := getdistribution(myrec.ConsultantTransactionid);
	naseg := getnaseg(myrec.clientid, myrec.periodid);
	if (naseg is null) then naseg := 0; end if;
	tkpseg := gettkpseg(myrec.clientid, myrec.periodid);
	if (tkpseg is null) then tkpseg := 0; end if;

	distvalue := 0;
	if (naseg <> 0) then
		distvalue := consseg * tkpseg / naseg;
	end if;
	
	RETURN distvalue;
END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION insCalls() RETURNS varchar(50) AS $$
BEGIN
	
	INSERT INTO calls (calldate, callmarker, calltime, extension, callline, calldetails, talktime, callcode)
	(SELECT newcalldate, callmarker, newcalltime, extension, callline, calldetails, newtalktime, callcode FROM calldumpview);

	DELETE FROM calldumps;
	
	RETURN 'Done';
END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION getincentive(integer, bigint) RETURNS float AS $$
DECLARE
    myrecord RECORD;
    incentrec RECORD;
	incentive float;
BEGIN
	incentive := 0;

	SELECT INTO incentrec sum(amount * (target - mintarget + 1) / 12) as sumamount FROM TargetView WHERE (ClientGroupID = $1) and (mintarget < ($2*12));
	SELECT INTO myrecord min(amount) as maxamount, mintarget FROM TargetView WHERE (ClientGroupID = $1) and (target >= ($2*12));

	IF (myrecord.maxamount IS NOT NULL) THEN
		incentive := incentrec.sumamount + (myrecord.maxamount * (mintarget/12 - $2));
	END IF;
	
	RETURN incentive;
END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION insDailyTransactions() RETURNS varchar(50) AS $$
DECLARE
	myrecord RECORD;
	myperiodid integer;
	myclientid integer;
BEGIN
	
	INSERT INTO dailyTransactions (PRDDate, clientid, PCC, DailyNetSegments, MTDNetSegments, YTDNetSegments)
	SELECT cast(split_part(dailysegments.prddate, '/', 3) || '-' || split_part(dailysegments.prddate, '/', 2) || '-' || split_part(dailysegments.prddate, '/', 1) as date), 
		pccs.clientid,  dailysegments.pcc,
		cast(dailysegments.dailynetsegments as integer), cast(dailysegments.mtdnetsegments as integer),
		cast(dailysegments.ytdnetsegments as integer)
	FROM dailysegments INNER JOIN pccs ON dailysegments.pcc = pccs.pcc;

	DELETE FROM dailysegments USING pccs WHERE dailysegments.pcc = pccs.pcc;
	
	RETURN 'Done';
END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION getClientCost(integer) RETURNS float AS $$
	SELECT CASE WHEN (sum(AssetSubTypes.segments) is null) THEN 0 ELSE sum(AssetSubTypes.segments) END
	FROM (AssetSubTypes INNER JOIN assets ON AssetSubTypes.AssetSubTypeID = Assets.AssetSubTypeID)
		INNER JOIN ClientAssets ON assets.assetid = ClientAssets.assetid
	WHERE (ClientAssets.clientid = $1) AND (ClientAssets.IsIssued = true) AND (IsRetrived = false);
$$ LANGUAGE SQL;

CREATE FUNCTION getBudgetSegs(int, date) RETURNS double precision AS $$
	SELECT CASE WHEN sum(Transactions.nasegs) > 0 THEN sum(Transactions.nasegs * (periods.BudgetRate + 100) / 100)
		ELSE sum(Transactions.nasegs * (100 - periods.BudgetRate) / 100) END 
	FROM Transactions INNER JOIN periods ON Transactions.periodid = periods.periodid 
	WHERE (Transactions.clientid = $1) 
		AND (extract(year from startdate) = (extract(year from $2)-1)) 
		AND (extract(month from startdate) = extract(month from $2));
$$ LANGUAGE SQL;

CREATE FUNCTION getClientCost(integer, date, date) RETURNS float AS $$
DECLARE
	clientcost float;
	myrec RECORD;
BEGIN
	SELECT INTO myrec sum(periodassetcosts.segments) as sumsegments
		FROM ((periodassetcosts INNER JOIN Assets ON periodassetcosts.AssetSubTypeID = Assets.AssetSubTypeID) 
			INNER JOIN ClientAssets ON ClientAssets.Assetid = Assets.Assetid) 
		WHERE (ClientAssets.clientid = $1) AND (periodassetcosts.periodid = $2) AND (ClientAssets.IsIssued = true) 
		AND (ClientAssets.dateIssued <= $3 + 14) AND ((ClientAssets.dateRetrived IS NULL) OR (ClientAssets.dateRetrived >= $3 + 14));

	clientcost := myrec.sumsegments;
	IF (clientcost is null) THEN
		clientcost := 0;
	END IF;
			
	RETURN clientcost;
END;
$$ LANGUAGE plpgsql;



