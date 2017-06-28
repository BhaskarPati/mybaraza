CREATE TABLE periods (
    periodid		serial primary key,
    startdate		date not null,
    enddate			date not null,
    closed			boolean not null default false,
    details 		text
);

CREATE TABLE categories (
	categoryid		serial primary key,
	categoryname		varchar(50),
	details			text
);

CREATE TABLE departments (
	departmentid		serial primary key,
	departmentname		varchar(50),
	details			text
);

CREATE TABLE items (
	itemid			serial primary key,
	categoryid		integer references categories,
	departmentid		integer references departments,
	itemname		varchar(50) not null,
	defaultunits		integer not null,
	defaultprice		float not null,
	saleitem		boolean default false not null,
	details			text
);

CREATE TABLE sales (
	saleid			serial primary key,
	itemid			integer references items,
	userid			integer references users,
	units			integer not null,
	unitprice		real not null,
	unitcost		real not null,
	commision		real not null,
	saledate		date,
	details			text
);

CREATE TABLE pcbudget (
    pcbudgetid		serial primary key,
    periodid		integer references periods,
    itemid			integer	references items,
	departmentid	integer references departments,
    units			integer not null,
    unitcost		float not null,    
    isapproved		boolean default false not null,
    details			text,
	UNIQUE (periodid, itemid)
);

CREATE TABLE pcexpenditure (
    pcexpenditureid	serial primary key,
    periodid		integer references periods,
    itemid			integer	references items,
	departmentid	integer references departments,
    units			integer not null,
    unitcost		float not null,
	receiptnumber	varchar(50),
	expdate			date default current_date not null,
	iscleared		boolean default false not null,
    details			text
);

CREATE TABLE pcbanking (
	pcbankingid		serial primary key,
	bankingdate		date not null,
	amount			float not null,
	narrative		varchar(240) not null,
	salereceipt		boolean default false not null,
	details			text
);

CREATE VIEW vwitems AS
	SELECT categories.categoryid, categories.categoryname, departments.departmentid, departments.departmentname,
		items.itemid, items.itemname, items.defaultunits, items.defaultprice, items.saleitem,
		(items.defaultunits * items.defaultprice) as defaultcost, items.details
	FROM (categories INNER JOIN items ON categories.categoryid = items.categoryid)
		INNER JOIN departments ON departments.departmentid = items.departmentid;

CREATE VIEW periodview AS
	SELECT periodid, startdate, enddate, details, date_part('month', startdate) as monthid,
		to_char(Periods.startdate, 'YYYY') as periodyear, to_char(Periods.startdate, 'Month') as periodmonth,
		(trunc((date_part('month', startdate)-1)/3)+1) as quarter
	FROM periods
	ORDER BY startdate;

CREATE VIEW periodyearview AS
	SELECT periodyear
	FROM periodview	
	GROUP BY periodyear
	ORDER BY periodyear;

CREATE FUNCTION getperiod(date) RETURNS integer AS $$
DECLARE
	myrec RECORD;
BEGIN
	SELECT INTO myrec periodid, startdate, enddate
	FROM periods
	WHERE (startdate<=$1) AND (enddate>=$1);

	IF myrec.periodid IS NULL THEN
		INSERT INTO periods (startdate, enddate)
		VALUES (date_trunc('month', $1), date_trunc('month', $1) + interval '1 month' - interval '1 day');

		SELECT INTO myrec periodid, startdate, enddate, closed
		FROM periods
		WHERE (startdate<=$1) AND (enddate>=$1);
	END IF;

    RETURN myrec.periodid;
END;
$$ LANGUAGE plpgsql;

CREATE VIEW pcbudgetview AS
	SELECT vwitems.itemid, vwitems.itemname, vwitems.categoryid, vwitems.categoryname,
		departments.departmentid, departments.departmentname,
		pcbudget.pcbudgetid, pcbudget.periodid, pcbudget.units, pcbudget.unitcost,
		(pcbudget.units * pcbudget.unitcost) as itemscost,
		pcbudget.isapproved, pcbudget.details, periodview.periodyear, periodview.periodmonth
	FROM ((vwitems INNER JOIN pcbudget ON vwitems.itemid = pcbudget.itemid)
		INNER JOIN departments ON pcbudget.departmentid = departments.departmentid)
		INNER JOIN periodview ON pcbudget.periodid = periodview.periodid;

CREATE VIEW pcexpenditureview AS
	SELECT vwitems.itemid, vwitems.itemname, vwitems.categoryid, vwitems.categoryname,
		departments.departmentid, departments.departmentname,
		pcexpenditure.pcexpenditureid, pcexpenditure.units, pcexpenditure.unitcost,
		(pcexpenditure.units * pcexpenditure.unitcost) as itemscost, pcexpenditure.expdate, pcexpenditure.receiptnumber,
		pcexpenditure.iscleared, pcexpenditure.details, periodview.periodid, periodview.periodyear, periodview.periodmonth
	FROM ((vwitems INNER JOIN pcexpenditure ON vwitems.itemid = pcexpenditure.itemid)
		INNER JOIN departments ON pcexpenditure.departmentid = departments.departmentid)
		INNER JOIN periodview ON pcexpenditure.periodid = periodview.periodid;

CREATE VIEW pcexpendituresum AS
	SELECT periodid, periodyear, periodmonth, itemid, itemname, categoryname, sum(units) as sumunits,
		avg(unitcost) as avgunitcost, sum(units * unitcost) as itemscost
	FROM pcexpenditureview
	GROUP BY periodid, periodyear, periodmonth, itemid, itemname, categoryname;

CREATE OR REPLACE FUNCTION insBudget() RETURNS TRIGGER AS $$
BEGIN
	INSERT INTO pcbudget (periodid, departmentid, itemid, units, unitcost)
	SELECT NEW.PeriodID, departmentid, itemid, defaultunits, defaultprice
	FROM items WHERE (defaultunits > 0);
	
	RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER insBudget AFTER INSERT ON periods
    FOR EACH ROW EXECUTE PROCEDURE insBudget();

CREATE FUNCTION getsumbudget(integer, integer) RETURNS float AS $$
    SELECT sum(units*unitcost) FROM pcbudget WHERE (periodid=$1) and (itemid=$2);
$$ LANGUAGE SQL;

CREATE FUNCTION getsumbudget(integer, integer, integer) RETURNS real AS $$
DECLARE
	budget real;
BEGIN		
	budget := getsumbudget($1, $2);
	IF budget is null THEN
		budget := $3;
    END IF;

    RETURN budget;
END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION getsumexpence(integer, integer) RETURNS float AS $$
    SELECT sum(units*unitcost) FROM pcexpenditure WHERE (periodid=$1) and (itemid=$2);
$$ LANGUAGE SQL;

CREATE FUNCTION getsumexpence(integer, integer, integer) RETURNS real AS $$
DECLARE
	expence real;
BEGIN		
	expence := getsumexpence($1, $2);
	IF expence is null THEN
		expence := $3;
    END IF;

    RETURN expence;
END;
$$ LANGUAGE plpgsql;

CREATE VIEW pcexpenditurediff AS
	SELECT vwitems.itemid, vwitems.categoryname, vwitems.itemname, vwitems.defaultunits, vwitems.defaultprice, vwitems.defaultcost,
		periodview.periodid, periodview.startdate, periodview.enddate, periodview.monthid,
		periodview.periodyear, periodview.periodmonth, periodview.quarter,
		getsumbudget(periodview.periodid, vwitems.itemid, 0) as itembudget,
		getsumexpence(periodview.periodid, vwitems.itemid, 0) as itemexpence,
		getsumbudget(periodview.periodid, vwitems.itemid, 0) - getsumexpence(periodview.periodid, vwitems.itemid, 0) as itemdiff
	FROM vwitems CROSS JOIN periodview
	WHERE (getsumbudget(periodview.periodid, vwitems.itemid, 0)<>0) OR (getsumexpence(periodview.periodid, vwitems.itemid, 0)<>0)
	ORDER BY vwitems.itemname;

CREATE FUNCTION periodbudget(integer) RETURNS float AS $$
    SELECT sum(units*unitcost) as cost FROM pcbudget WHERE (periodid=$1);
$$ LANGUAGE SQL;

CREATE FUNCTION periodexpenditure(integer) RETURNS float AS $$
    SELECT sum(units*unitcost) as cost FROM pcexpenditure WHERE (periodid=$1);
$$ LANGUAGE SQL;

CREATE VIEW periodsummary AS
	SELECT periodid, startdate, enddate, monthid, periodyear, periodmonth, quarter,
		periodbudget(periodid) as periodbudget, periodexpenditure(periodid) as periodexpenditure, 
		(periodbudget(periodid) - periodexpenditure(periodid)) as budgetdiff
	FROM periodview
	ORDER BY startdate;

CREATE VIEW vwsales AS
	SELECT items.itemid, items.itemname, users.userid, users.username, users.fullname,
		sales.saleid, sales.saledate, sales.units, sales.unitprice, sales.unitcost, 
		(sales.units * sales.unitcost) as salecost, (sales.units * sales.unitprice) as saleprice,
		sales.commision, (sales.commision + (sales.units * sales.unitprice)) as receipt,
		(sales.units * (sales.unitprice - sales.unitcost)) as grossprofit
	FROM (sales INNER JOIN items ON sales.itemid = items.itemid)
		INNER JOIN users ON sales.userid = users.userid;

INSERT INTO items (itemid, itemname, defaultunits, defaultprice) VALUES('1', 'Sugar', '6', '125');
INSERT INTO items (itemid, itemname, defaultunits, defaultprice) VALUES('2', 'Tea Bugs', '4', '120');
INSERT INTO items (itemid, itemname, defaultunits, defaultprice) VALUES('3', 'Coffee', '2', '490');
INSERT INTO items (itemid, itemname, defaultunits, defaultprice) VALUES('4', 'Disposable cups', '25', '45');
INSERT INTO items (itemid, itemname, defaultunits, defaultprice) VALUES('5', 'Home Dry ', '10', '165');
INSERT INTO items (itemid, itemname, defaultunits, defaultprice) VALUES('6', 'Velvex', '2', '50');
INSERT INTO items (itemid, itemname, defaultunits, defaultprice) VALUES('7', 'Kipande', '1', '50');
INSERT INTO items (itemid, itemname, defaultunits, defaultprice) VALUES('8', 'Tissue', '2', '144');
INSERT INTO items (itemid, itemname, defaultunits, defaultprice) VALUES('9', 'Cloth Pm', '1', '1500');
INSERT INTO items (itemid, itemname, defaultunits, defaultprice) VALUES('10', 'CD bags', '100', '2');
INSERT INTO items (itemid, itemname, defaultunits, defaultprice) VALUES('11', 'Blank CDs', '100', '15');
INSERT INTO items (itemid, itemname, defaultunits, defaultprice) VALUES('12', 'Biros', '20', '15');
INSERT INTO items (itemid, itemname, defaultunits, defaultprice) VALUES('13', 'Cleaning cloth', '2', '25');
INSERT INTO items (itemid, itemname, defaultunits, defaultprice) VALUES('14', 'Scissors', '1', '250');
INSERT INTO items (itemid, itemname, defaultunits, defaultprice) VALUES('15', 'Fuses', '40', '5');
INSERT INTO items (itemid, itemname, defaultunits, defaultprice) VALUES('16', 'Black Cartridge', '1', '2000');
INSERT INTO items (itemid, itemname, defaultunits, defaultprice) VALUES('17', 'File', '4', '50');
INSERT INTO items (itemid, itemname, defaultunits, defaultprice) VALUES('18', 'CD Marker', '2', '150');
INSERT INTO items (itemid, itemname, defaultunits, defaultprice) VALUES('19', 'Labels', '5', '20');
INSERT INTO items (itemid, itemname, defaultunits, defaultprice) VALUES('20', 'Stickers', '5', '60');
INSERT INTO items (itemid, itemname, defaultunits, defaultprice) VALUES('21', 'plugs', '10', '60');
INSERT INTO items (itemid, itemname, defaultunits, defaultprice) VALUES('22', 'Spoons', '5', '15');
INSERT INTO items (itemid, itemname, defaultunits, defaultprice) VALUES('23', 'Pure Chamomille Tea', '2', '140');
INSERT INTO items (itemid, itemname, defaultunits, defaultprice) VALUES('24', 'Beta Tea', '1', '140');
INSERT INTO items (itemid, itemname, defaultunits, defaultprice) VALUES('25', 'Cellotape', '4', '40');
INSERT INTO items (itemid, itemname, defaultunits, defaultprice) VALUES('26', 'DVD R', '5', '100');
INSERT INTO items (itemid, itemname, defaultunits, defaultprice) VALUES('27', 'Colour Catridge', '1', '2000');
INSERT INTO items (itemid, itemname, defaultunits, defaultprice) VALUES('28', 'Water', '16', '279');
INSERT INTO items (itemid, itemname, defaultunits, defaultprice) VALUES('29', 'Milk', '108', '30');
INSERT INTO items (itemid, itemname, defaultunits, defaultprice) VALUES('30', 'Newspaper – Weekend', '4', '40');
INSERT INTO items (itemid, itemname, defaultunits, defaultprice) VALUES('31', 'Newspaper - Weekday', '5', '35');
INSERT INTO items (itemid, itemname, defaultunits, defaultprice) VALUES('32', 'Card', '4', '100');
INSERT INTO items (itemid, itemname, defaultunits, defaultprice) VALUES('33', 'Office CellPhone', '1', '7000');

