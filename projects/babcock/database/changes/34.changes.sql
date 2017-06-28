CREATE OR REPLACE FUNCTION ins_sublevel_org_id() RETURNS trigger AS $$
BEGIN
	SELECT org_id INTO NEW.org_id
	FROM sublevels
	WHERE (sublevelid = NEW.sublevelid);
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER ins_qorg_id ON qcharges;
DROP TRIGGER ins_qorg_id ON qmcharges;
DROP TRIGGER ins_qorg_id ON qchargedefinations;
DROP TRIGGER ins_qorg_id ON qmchargedefinations

CREATE TRIGGER ins_sublevel_org_id BEFORE INSERT OR UPDATE
  ON qcharges FOR EACH ROW EXECUTE PROCEDURE ins_sublevel_org_id();
CREATE TRIGGER ins_sublevel_org_id BEFORE INSERT OR UPDATE
  ON qmcharges FOR EACH ROW EXECUTE PROCEDURE ins_sublevel_org_id();
CREATE TRIGGER ins_sublevel_org_id BEFORE INSERT OR UPDATE
  ON qchargedefinations FOR EACH ROW EXECUTE PROCEDURE ins_sublevel_org_id();
CREATE TRIGGER ins_sublevel_org_id BEFORE INSERT OR UPDATE
  ON qmchargedefinations FOR EACH ROW EXECUTE PROCEDURE ins_sublevel_org_id();
  
INSERT INTO qchargedefinations (sublevelid, chargetypeid, quarterid, org_id, studylevel, amount)
SELECT 'UGPM', chargetypeid, quarterid, 1, studylevel, amount
FROM qchargedefinations
WHERE (quarterid = '2013/2014.1') and (studylevel = 100);

UPDATE qstudents SET sublevelid = 'UGPM'
WHERE qstudentid IN
(SELECT vwqstudentbalances.qstudentid
FROM vwqstudentbalances LEFT JOIN 
(SELECT qstudentid FROM vwsuncharges WHERE quarterid = '2013/2014.1') as aa
ON vwqstudentbalances.qstudentid = aa.qstudentid
WHERE (vwqstudentbalances.finaceapproval = true)
AND (vwqstudentbalances.quarterid = '2013/2014.1')
AND (aa.qstudentid is null));

CREATE OR REPLACE VIEW vwqstudentcharges AS 
	SELECT vwstudentmajors.denominationid, vwstudentmajors.denominationname, vwstudentmajors.studentid, vwstudentmajors.studentname, 
		vwstudentmajors.nationality, vwstudentmajors.nationalitycountry, vwstudentmajors.sex, vwstudentmajors.maritalstatus, vwstudentmajors.birthdate, 
		vwstudentmajors.accountnumber, vwstudentmajors.mobile, vwstudentmajors.telno, vwstudentmajors.email, vwstudentmajors.emailuser, 
		vwstudentmajors.picturefile, vwstudentmajors.degreelevelid, vwstudentmajors.degreelevelname, sublevels.sublevelid, sublevels.sublevelname,
		vwstudentmajors.degreeid, vwstudentmajors.degreename, vwstudentmajors.studentdegreeid, vwstudentmajors.completed, 
		vwstudentmajors.started, vwstudentmajors.cleared, vwstudentmajors.clearedate, vwstudentmajors.graduated, vwstudentmajors.graduatedate, 
		vwstudentmajors.dropout, vwstudentmajors.transferin, vwstudentmajors.transferout, vwstudentmajors.schoolid, vwstudentmajors.schoolname, 
		vwstudentmajors.departmentid, vwstudentmajors.departmentname, vwstudentmajors.majorid, vwstudentmajors.majorname, vwstudentmajors.electivecredit, 
		vwstudentmajors.domajor, vwstudentmajors.dominor, vwstudentmajors.studentmajorid, vwstudentmajors.major, vwstudentmajors.nondegree, 
		vwstudentmajors.premajor, qstudents.qstudentid, qstudents.quarterid, qstudents.qresidenceid, qstudents.charges, qstudents.probation, 
		qstudents.offcampus, qstudents.citizengrade, qstudents.citizenmarks, qstudents.blockname, qstudents.roomnumber, qstudents.currbalance, 
		qstudents.studylevel, qstudents.mealtype, qstudents.applicationtime, qstudents.finalised, qstudents.finaceapproval, qstudents.majorapproval, 
		qstudents.chaplainapproval, qstudents.studentdeanapproval, qstudents.overloadapproval, qstudents.departapproval, qstudents.overloadhours, 
		qstudents.intersession, qstudents.closed, qstudents.printed, qstudents.approved, qstudents.financenarrative, qstudents.noapproval, 
		qstudents.premiumhall, qstudents.paymenttype, qstudents.ispartpayment, qstudents.financeclosed, qstudents.mealticket, qstudents.approveddate, 
		qstudents.picked, qstudents.pickeddate, qstudents.arrivaldate, qstudents.hallreceipt, qstudents.lrfpicked, qstudents.lrfpickeddate, 
		qstudents.org_id, 
		quarters.active, qresidenceview.residenceid, qresidenceview.residencename, qresidenceview.residencecharge,

		qcharges.fullfees + qresidenceview.full_charges + COALESCE(qmcharges.fullcharge, 0::double precision) + 
		CASE
			WHEN qstudents.offcampus = true THEN 0::double precision
			WHEN qstudents.mealtype::text = 'BLS'::text THEN qcharges.fullmeal3fees + COALESCE(qmcharges.meal3charge * 2, 0::double precision)
			ELSE qcharges.fullmeal2fees + COALESCE(qmcharges.meal2charge * 2, 0::double precision)
			END AS fullfees, 

		qcharges.fees + qresidenceview.charges + COALESCE(qmcharges.charge, 0::double precision) + 
		CASE
			WHEN qstudents.offcampus = true THEN 0::double precision
			WHEN qstudents.mealtype::text = 'BLS'::text THEN qcharges.meal3fees + COALESCE(qmcharges.meal3charge, 0::double precision)
			ELSE qcharges.meal2fees + COALESCE(qmcharges.meal2charge, 0::double precision)
		END AS fees

	FROM vwstudentmajors INNER JOIN (qstudents INNER JOIN quarters ON qstudents.quarterid::text = quarters.quarterid::text) 
			ON vwstudentmajors.studentdegreeid = qstudents.studentdegreeid
		INNER JOIN qresidenceview ON qstudents.qresidenceid = qresidenceview.qresidenceid
		INNER JOIN sublevels ON qstudents.sublevelid = sublevels.sublevelid
		INNER JOIN qcharges ON (qstudents.sublevelid = qcharges.sublevelid)
			AND (qstudents.quarterid::text = qcharges.quarterid::text)
			AND (qstudents.studylevel = qcharges.studylevel)
		LEFT JOIN qmcharges ON (vwstudentmajors.majorid::text = qmcharges.majorid::text)
			AND (qstudents.quarterid::text = qmcharges.quarterid::text)
			AND (qstudents.studylevel = qmcharges.studylevel)
			AND (qstudents.sublevelid = qmcharges.sublevelid);
			
DROP VIEW vwqmajorchargesummary;
CREATE VIEW vwqmajorchargesummary AS
	SELECT vwqmajorchargelists.quarterid, vwqmajorchargelists.majorid, vwqmajorchargelists.majorname, 
		vwqmajorchargelists.accountnumber, vwqmajorchargelists.accountcode, 
		vwqmajorchargelists.chargetypeid, vwqmajorchargelists.chargetypename, 
		vwqmajorchargelists.sublevelid, vwqmajorchargelists.sublevelname, vwqmajorchargelists.studylevel, 
		sum(vwqmajorchargelists.nonresident) as nonresident, sum(vwqmajorchargelists.regural) as regural, 
		sum(vwqmajorchargelists.threemeals) as threemeals, 
		sum(vwqmajorchargelists.premialhall) as premialhall, 
		sum(vwqmajorchargelists.premialhallthree) as premialhallthree
	FROM vwqmajorchargelists
	GROUP BY vwqmajorchargelists.quarterid, vwqmajorchargelists.majorid, vwqmajorchargelists.majorname, 
		vwqmajorchargelists.accountnumber, vwqmajorchargelists.accountcode, 
		vwqmajorchargelists.chargetypeid, vwqmajorchargelists.chargetypename, 
		vwqmajorchargelists.sublevelid, vwqmajorchargelists.sublevelname, vwqmajorchargelists.studylevel;
		
DROP VIEW vwsuncharges;
CREATE VIEW vwsuncharges AS 
	SELECT vwqmajorchargesummary.accountnumber AS chargeaccount, vwqmajorchargesummary.accountcode, 
		vwqmajorchargesummary.chargetypeid, vwqmajorchargesummary.chargetypename, 
		vwqmajorchargesummary.quarterid, vwqmajorchargesummary.studylevel, 
		vwqmajorchargesummary.majorid, vwqmajorchargesummary.majorname, 
		vwqmajorchargesummary.sublevelid, vwqmajorchargesummary.sublevelname,
        CASE WHEN vwqstudentbalances.offcampus = true THEN vwqmajorchargesummary.nonresident
            WHEN vwqstudentbalances.mealtype::text = 'BLS'::text THEN vwqmajorchargesummary.threemeals
            ELSE vwqmajorchargesummary.regural END AS unitfees, 
		vwqstudentbalances.accountnumber, vwqstudentbalances.studentname, vwqstudentbalances.fees, 
		vwqstudentbalances.residencecharge, vwqstudentbalances.picked, vwqstudentbalances.qstudentid,
		vwqstudentbalances.mealtype
	FROM vwqmajorchargesummary JOIN vwqstudentbalances ON 
		(vwqmajorchargesummary.majorid = vwqstudentbalances.majorid) AND
		(vwqmajorchargesummary.sublevelid = vwqstudentbalances.sublevelid) AND 
		(vwqmajorchargesummary.studylevel = vwqstudentbalances.studylevel) AND 
		(vwqmajorchargesummary.quarterid = vwqstudentbalances.quarterid)
	WHERE (vwqstudentbalances.finaceapproval = true)
	ORDER BY vwqstudentbalances.accountnumber;
	
	

INSERT INTO qcharges (degreelevelid, quarterid, org_id, sublevelid, studylevel)
SELECT sublevels.degreelevelid, aa.quarterid, aa.org_id, aa.sublevelid, aa.studylevel
FROM sublevels INNER JOIN 
(SELECT qstudents.quarterid, qstudents.org_id, qstudents.sublevelid, qstudents.studylevel
FROM qstudents LEFT JOIN vwqstudentcharges ON qstudents.qstudentid = vwqstudentcharges.qstudentid
WHERE (vwqstudentcharges.qstudentid is null) AND (qstudents.finaceapproval = true)
GROUP BY qstudents.quarterid, qstudents.org_id, qstudents.sublevelid, qstudents.studylevel
ORDER BY qstudents.quarterid, qstudents.sublevelid, qstudents.studylevel) as aa
ON sublevels.sublevelid = aa.sublevelid
LEFT JOIN qcharges ON
qcharges.quarterid = aa.quarterid and qcharges.sublevelid = aa.sublevelid and qcharges.studylevel = aa.studylevel
WHERE qcharges.quarterid is null;


