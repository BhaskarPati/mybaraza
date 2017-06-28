DROP VIEW pcexpendituresum;

CREATE VIEW pcexpendituresum AS
	SELECT periodid, periodyear, periodmonth, itemid, itemname, categoryname, sum(units) as sumunits,
		avg(unitcost) as avgunitcost, sum(units * unitcost) as itemscost
	FROM pcexpenditureview
	GROUP BY periodid, periodyear, periodmonth, itemid, itemname, categoryname;

DROP VIEW pcexpenditurediff;

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
