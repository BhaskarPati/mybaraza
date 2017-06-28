
ALTER TABLE qcharges ADD sublevelid			varchar(12) references sublevels;
ALTER TABLE qcharges DROP CONSTRAINT qcharges_quarterid_degreelevelid_studylevel_key;
ALTER TABLE qcharges ADD CONSTRAINT qcharges_qdss_unique UNIQUE (quarterid, degreelevelid, studylevel, sublevelid);
CREATE INDEX qcharges_sublevelid ON qcharges (sublevelid);

UPDATE qcharges SET sublevelid = sublevels.sublevelid
FROM sublevels WHERE qcharges.degreelevelid = sublevels.degreelevelid;

ALTER TABLE qchargedefinations ADD sublevelid				varchar(12) references sublevels;
CREATE INDEX qchargedefinations_sublevelid ON qchargedefinations (sublevelid);
ALTER TABLE qchargedefinations DROP CONSTRAINT qchargedefinations_chargetypeid_quarterid_studylevel_key;
ALTER TABLE qchargedefinations ADD CONSTRAINT qchargedefinations_cqss_unique UNIQUE (chargetypeid, quarterid, studylevel, sublevelid);
UPDATE qchargedefinations SET sublevelid = 'UNDM';

DROP TRIGGER updqstudents ON qstudents;

ALTER TABLE qstudents ADD sublevelid			varchar(12) references sublevels;
CREATE INDEX qstudents_sublevelid ON qstudents (sublevelid);

UPDATE qstudents SET sublevelid = studentdegrees.sublevelid
FROM studentdegrees WHERE (qstudents.studentdegreeid = studentdegrees.studentdegreeid);

CREATE OR REPLACE FUNCTION ins_qstudents() RETURNS trigger AS $$
BEGIN
	SELECT org_id, sublevelid INTO NEW.org_id, NEW.sublevelid
	FROM studentdegrees
	WHERE (studentdegreeid = NEW.studentdegreeid);

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ins_qstudents BEFORE INSERT
  ON qstudents FOR EACH ROW EXECUTE PROCEDURE ins_qstudents();

CREATE TRIGGER updqstudents AFTER UPDATE ON qstudents
  FOR EACH ROW EXECUTE PROCEDURE updqstudents();

INSERT INTO sublevels (sublevelid, degreelevelid, levellocationid, org_id, sublevelname)
VALUES ('UGPM', 'UND', 1, 0, 'Undergraduate - Pre-medical');
INSERT INTO sublevels (sublevelid, degreelevelid, levellocationid, org_id, sublevelname)
VALUES ('MASE', 'MAS', 1, 2, 'Masters - Elongated');

------------ New changes


DELETE FROM qstudents WHERE studentdegreeid is null;
DELETE FROM qstudents WHERE quarterid is null;

CREATE INDEX qcharges_org_id ON qcharges (org_id);
ALTER TABLE qchargedefinations ADD org_id					integer references orgs;
CREATE INDEX qchargedefinations_org_id ON qchargedefinations (org_id);

ALTER TABLE qmcharges DROP CONSTRAINT qmcharges_quarterid_majorid_studylevel_key;
ALTER TABLE qmcharges ADD sublevelid			varchar(12) references sublevels;
CREATE INDEX qmcharges_sublevelid ON qmcharges (sublevelid);
CREATE INDEX qmcharges_org_id ON qmcharges (org_id);
ALTER TABLE qmcharges ADD CONSTRAINT qmcharges_qmss_key UNIQUE (quarterid, majorid, studylevel, sublevelid);

ALTER TABLE qmchargedefinations DROP CONSTRAINT qmchargedefinations_chargetypeid_quarterid_majorid_studylev_key;
ALTER TABLE qmchargedefinations ADD sublevelid				varchar(12) references sublevels;
CREATE INDEX qmchargedefinations_sublevelid ON qmchargedefinations (sublevelid);
CREATE INDEX qmchargedefinations_org_id ON qmchargedefinations (org_id);
ALTER TABLE qmchargedefinations ADD CONSTRAINT qmchargedefinations_cqmss_key UNIQUE (chargetypeid, quarterid, majorid, studylevel, sublevelid);

UPDATE quarters SET org_id = 0;
UPDATE quarters SET org_id = 1 WHERE quarterid ilike '%M%';
UPDATE quarters SET org_id = 2 WHERE quarterid ilike '%P%';

UPDATE qcharges SET sublevelid = 'UNDM', org_id = 0;
UPDATE qcharges SET sublevelid = 'MEDI', org_id = 1 WHERE quarterid ilike '%M%';
UPDATE qcharges SET sublevelid = 'MAST', org_id = 2 WHERE quarterid ilike '%P%';
UPDATE qcharges SET sublevelid = 'PHD' WHERE degreelevelid = 'PHD';
UPDATE qcharges SET sublevelid = 'PGDI' WHERE degreelevelid = 'PGD';
UPDATE qmcharges SET sublevelid = 'UNDM', org_id = 0;
UPDATE qmcharges SET sublevelid = 'MEDI', org_id = 1 WHERE quarterid ilike '%M%';
UPDATE qmcharges SET sublevelid = 'MAST', org_id = 2 WHERE quarterid ilike '%P%';

UPDATE qchargedefinations SET sublevelid = 'UNDM', org_id = 0;
UPDATE qchargedefinations SET sublevelid = 'MEDI', org_id = 1 WHERE quarterid ilike '%M%';
UPDATE qchargedefinations SET sublevelid = 'MAST', org_id = 2 WHERE quarterid ilike '%P%';
UPDATE qmchargedefinations SET sublevelid = 'UNDM', org_id = 0;
UPDATE qmchargedefinations SET sublevelid = 'MEDI', org_id = 1 WHERE quarterid ilike '%M%';
UPDATE qmchargedefinations SET sublevelid = 'MAST', org_id = 2 WHERE quarterid ilike '%P%';

INSERT INTO sublevels (sublevelid, degreelevelid, levellocationid, org_id, sublevelname)
VALUES ('PHDE', 'PHD', 1, 2, 'Doctorate - Elongated');

CREATE OR REPLACE VIEW vwqstudentcharges AS 
	SELECT vwstudentmajors.denominationid, vwstudentmajors.denominationname, vwstudentmajors.studentid, vwstudentmajors.studentname, 
		vwstudentmajors.nationality, vwstudentmajors.nationalitycountry, vwstudentmajors.sex, vwstudentmajors.maritalstatus, vwstudentmajors.birthdate, 
		vwstudentmajors.accountnumber, vwstudentmajors.mobile, vwstudentmajors.telno, vwstudentmajors.email, vwstudentmajors.emailuser, 
		vwstudentmajors.picturefile, vwstudentmajors.degreelevelid, vwstudentmajors.degreelevelname, vwstudentmajors.sublevelid, 
		vwstudentmajors.sublevelname, vwstudentmajors.degreeid, vwstudentmajors.degreename, vwstudentmajors.studentdegreeid, vwstudentmajors.completed, 
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

	FROM vwstudentmajors
		JOIN (qstudents JOIN quarters ON qstudents.quarterid::text = quarters.quarterid::text) 
			ON vwstudentmajors.studentdegreeid = qstudents.studentdegreeid
		JOIN qresidenceview ON qstudents.qresidenceid = qresidenceview.qresidenceid
		JOIN qcharges ON (vwstudentmajors.degreelevelid::text = qcharges.degreelevelid::text)
			AND (qstudents.quarterid::text = qcharges.quarterid::text)
			AND (qstudents.studylevel = qcharges.studylevel)
			AND (qstudents.sublevelid = qcharges.sublevelid)
		LEFT JOIN qmcharges ON (vwstudentmajors.majorid::text = qmcharges.majorid::text)
			AND (qstudents.quarterid::text = qmcharges.quarterid::text)
			AND (qstudents.studylevel = qmcharges.studylevel)
			AND (qstudents.sublevelid = qmcharges.sublevelid);

DROP VIEW chargeview;
CREATE VIEW chargeview AS
	SELECT degreelevels.degreelevelid, degreelevels.degreelevelname, 
		sublevels.sublevelid, sublevels.sublevelname,
		qcharges.org_id, qcharges.qchargeid, qcharges.quarterid, qcharges.studylevel, qcharges.narrative,
		qcharges.fees, qcharges.fullfees, qcharges.meal2fees, qcharges.meal3fees, qcharges.premiumhall,
		qcharges.minimalfees, qcharges.firstinstalment, qcharges.firstdate, 
		qcharges.secondinstalment, qcharges.seconddate,
		substring(qcharges.quarterid from 1 for 9)  as quarteryear, substring(qcharges.quarterid from 11 for 2)  as quarter
	FROM degreelevels INNER JOIN qcharges ON degreelevels.degreelevelid = qcharges.degreelevelid
		INNER JOIN sublevels ON qcharges.sublevelid = sublevels.sublevelid;

DROP VIEW qchargeview;
CREATE VIEW qchargeview AS
	SELECT quarters.quarterid, quarters.qstart, quarters.qlatereg, quarters.qlatechange, quarters.qlastdrop,
		quarters.qend, quarters.active, quarters.feesline, quarters.resline, 
		substring(quarters.quarterid from 1 for 9)  as quarteryear, substring(quarters.quarterid from 11 for 2)  as quarter,
		degreelevels.degreelevelid, degreelevels.degreelevelname, 
		sublevels.sublevelid, sublevels.sublevelname,
		qcharges.org_id, qcharges.qchargeid, qcharges.studylevel, qcharges.narrative,
		qcharges.fees, qcharges.fullfees, qcharges.meal2fees, qcharges.meal3fees, qcharges.premiumhall,
		qcharges.minimalfees, qcharges.firstinstalment, qcharges.firstdate,
		qcharges.secondinstalment, qcharges.seconddate
	FROM quarters INNER JOIN qcharges ON quarters.quarterid = qcharges.quarterid
		INNER JOIN degreelevels ON degreelevels.degreelevelid = qcharges.degreelevelid
		INNER JOIN sublevels ON qcharges.sublevelid = sublevels.sublevelid;

DROP VIEW qmchargeview;
CREATE VIEW qmchargeview AS
	SELECT quarters.quarterid, quarters.qstart, quarters.qlatereg, quarters.qlatechange, quarters.qlastdrop,
		majors.majorid, majors.majorname,
		sublevels.sublevelid, sublevels.sublevelname,
		qmcharges.org_id, qmcharges.qmchargeid, qmcharges.studylevel, qmcharges.charge, qmcharges.fullcharge, 
		qmcharges.narrative
	FROM (quarters INNER JOIN qmcharges ON quarters.quarterid = qmcharges.quarterid)
		INNER JOIN majors ON qmcharges.majorid = majors.majorid
		INNER JOIN sublevels ON qmcharges.sublevelid = sublevels.sublevelid;

DROP VIEW vwqmajorcharges;
DROP VIEW vwqcharges;
CREATE VIEW vwqcharges AS
	SELECT majors.majorid, majors.majorname, 
		qcharges.org_id, qcharges.degreelevelid, qcharges.quarterid, qcharges.studylevel, qcharges.sublevelid,
		qcharges.fullfees, (qcharges.fullfees + qcharges.fullmeal2fees) as fullmeal2fees, 
		(qcharges.fullfees + qcharges.fullmeal3fees) as fullmeal3fees, 
		qcharges.fees, (qcharges.fees + qcharges.meal2fees) as meal2fees, (qcharges.fees + qcharges.meal3fees) as meal3fees,
		(CASE WHEN substring(qcharges.quarterid from 11 for 2) = '1' THEN
		(2 * qcharges.premiumhall + qcharges.fullfees + qcharges.fullmeal2fees)
		ELSE (qcharges.premiumhall + qcharges.fullfees + qcharges.fullmeal2fees) END) as phfullmeal2fees, 
		(CASE WHEN substring(qcharges.quarterid from 11 for 2) = '1' THEN
		(2 * qcharges.premiumhall + qcharges.fullfees + qcharges.fullmeal3fees)
		ELSE (qcharges.premiumhall + qcharges.fullfees + qcharges.fullmeal3fees) END) as phfullmeal3fees, 
		(qcharges.premiumhall + qcharges.fees + qcharges.meal2fees) as phmeal2fees, 
		(qcharges.premiumhall + qcharges.fees + qcharges.meal3fees) as phmeal3fees
	FROM qcharges CROSS JOIN majors
	WHERE (qcharges.org_id = majors.org_id);

CREATE VIEW vwqmajorcharges AS
	SELECT vwqcharges.majorid, vwqcharges.majorname, vwqcharges.degreelevelid, vwqcharges.sublevelid,
		vwqcharges.quarterid, vwqcharges.studylevel, vwqcharges.org_id,
		(COALESCE(qmcharges.fullcharge, 0) + vwqcharges.fullfees) as fullfees, 
		(COALESCE(qmcharges.fullcharge, 0) + COALESCE(qmcharges.meal2charge * 2, 0) + vwqcharges.fullmeal2fees) as fullmeal2fees, 
		(COALESCE(qmcharges.fullcharge, 0) + COALESCE(qmcharges.meal3charge * 2, 0) + vwqcharges.fullmeal3fees) as fullmeal3fees, 
		(COALESCE(qmcharges.charge, 0) + vwqcharges.fees) as fees, 
		(COALESCE(qmcharges.charge, 0) + COALESCE(qmcharges.meal2charge, 0) + vwqcharges.meal2fees) as meal2fees, 
		(COALESCE(qmcharges.charge, 0) + COALESCE(qmcharges.meal3charge, 0) + vwqcharges.meal3fees) as meal3fees,
		(COALESCE(qmcharges.fullcharge, 0) + COALESCE(qmcharges.meal2charge, 0) + COALESCE(qmcharges.phallcharge, 0) + vwqcharges.phfullmeal2fees) as phfullmeal2fees, 
		(COALESCE(qmcharges.fullcharge, 0) + COALESCE(qmcharges.meal3charge, 0) + COALESCE(qmcharges.phallcharge, 0) + vwqcharges.phfullmeal3fees) as phfullmeal3fees,
		(COALESCE(qmcharges.charge, 0) + COALESCE(qmcharges.meal2charge, 0) + COALESCE(qmcharges.phallcharge, 0) + vwqcharges.phmeal2fees) as phmeal2fees, 
		(COALESCE(qmcharges.charge, 0) + COALESCE(qmcharges.meal3charge, 0) + COALESCE(qmcharges.phallcharge, 0) + vwqcharges.phmeal3fees) as phmeal3fees
	FROM vwqcharges LEFT JOIN qmcharges ON (vwqcharges.quarterid = qmcharges.quarterid) 
		AND (vwqcharges.majorid = qmcharges.majorid) AND (vwqcharges.studylevel = qmcharges.studylevel)
		AND (vwqcharges.sublevelid = qmcharges.sublevelid);

DROP VIEW vwsuncharges;
DROP VIEW vwqmajorchargesummary;
DROP VIEW vwqmajorchargelists;
DROP VIEW vwqchargedefinations;
DROP VIEW vwqmchargedefinations;
CREATE VIEW vwqchargedefinations AS
	SELECT chargetypes.chargetypeid, chargetypes.chargetypename, chargetypes.accountnumber, chargetypes.accountcode,
		sublevels.sublevelid, sublevels.sublevelname,
		qchargedefinations.org_id, qchargedefinations.qchargedefinationid,
		qchargedefinations.studylevel, qchargedefinations.amount, qchargedefinations.narrative, quarters.quarterid,
		(CASE WHEN (chargetypes.offcampus = true) THEN qchargedefinations.amount ELSE 0 END) as nonresident,
		(CASE WHEN (chargetypes.oncampus = true) THEN qchargedefinations.amount ELSE 0 END) as regural,
		(CASE WHEN (chargetypes.chargetypeid = 2) THEN quarters.mealcharge ELSE 0 END) as addmeal,
		(CASE WHEN (chargetypes.chargetypeid = 3) THEN quarters.premialhall ELSE 0 END) as premialhall
	FROM (chargetypes INNER JOIN qchargedefinations ON chargetypes.chargetypeid = qchargedefinations.chargetypeid)
		INNER JOIN quarters ON qchargedefinations.quarterid = quarters.quarterid
		INNER JOIN sublevels ON qchargedefinations.sublevelid = sublevels.sublevelid;

CREATE VIEW vwqmchargedefinations AS
	SELECT chargetypes.chargetypeid, chargetypes.chargetypename, chargetypes.accountnumber, chargetypes.accountcode,
		chargetypes.oncampus, chargetypes.offcampus, majors.majorid, majors.majorname, 
		sublevels.sublevelid, sublevels.sublevelname,
		qmchargedefinations.qmchargedefinationid, qmchargedefinations.quarterid,
		qmchargedefinations.studylevel, qmchargedefinations.amount, qmchargedefinations.narrative
	FROM (chargetypes INNER JOIN qmchargedefinations ON chargetypes.chargetypeid = qmchargedefinations.chargetypeid)
		INNER JOIN majors ON qmchargedefinations.majorid = majors.majorid
		INNER JOIN sublevels ON qmchargedefinations.sublevelid = sublevels.sublevelid;

CREATE VIEW vwqmajorchargelists AS
	(SELECT majors.majorid, majors.majorname, 
		vwqchargedefinations.chargetypeid, vwqchargedefinations.chargetypename,
		vwqchargedefinations.sublevelid, vwqchargedefinations.sublevelname,
		vwqchargedefinations.accountnumber, vwqchargedefinations.accountcode,
		vwqchargedefinations.qchargedefinationid, vwqchargedefinations.quarterid,
		vwqchargedefinations.studylevel,  vwqchargedefinations.narrative,
		vwqchargedefinations.nonresident, vwqchargedefinations.regural, 
		(vwqchargedefinations.regural + vwqchargedefinations.addmeal) as threemeals,
		(vwqchargedefinations.regural + vwqchargedefinations.premialhall) as premialhall,
		(vwqchargedefinations.regural + vwqchargedefinations.premialhall + vwqchargedefinations.addmeal) as premialhallthree
	FROM (majors CROSS JOIN vwqchargedefinations)
	WHERE (majors.org_id = vwqchargedefinations.org_id))
	UNION
	(SELECT vwqmchargedefinations.majorid, vwqmchargedefinations.majorname,
		vwqmchargedefinations.chargetypeid, vwqmchargedefinations.chargetypename, 
		vwqmchargedefinations.sublevelid, vwqmchargedefinations.sublevelname,
		vwqmchargedefinations.accountnumber, vwqmchargedefinations.accountcode, 
		vwqmchargedefinations.qmchargedefinationid, vwqmchargedefinations.quarterid, 
		vwqmchargedefinations.studylevel, vwqmchargedefinations.narrative,
		vwqmchargedefinations.amount, vwqmchargedefinations.amount, vwqmchargedefinations.amount,
		vwqmchargedefinations.amount, vwqmchargedefinations.amount
	FROM vwqmchargedefinations);

CREATE VIEW vwqmajorchargesummary AS
	SELECT vwqmajorchargelists.quarterid, vwqmajorchargelists.majorid, vwqmajorchargelists.majorname, 
		vwqmajorchargelists.sublevelid, vwqmajorchargelists.sublevelname, vwqmajorchargelists.studylevel, 
		sum(vwqmajorchargelists.nonresident) as nonresident, sum(vwqmajorchargelists.regural) as regural, sum(vwqmajorchargelists.threemeals) as threemeals, 
		sum(vwqmajorchargelists.premialhall) as premialhall, sum(vwqmajorchargelists.premialhallthree) as premialhallthree
	FROM vwqmajorchargelists
	GROUP BY vwqmajorchargelists.quarterid, vwqmajorchargelists.majorid, vwqmajorchargelists.majorname, 
		vwqmajorchargelists.sublevelid, vwqmajorchargelists.sublevelname, vwqmajorchargelists.studylevel;

CREATE VIEW vwsuncharges AS 
	SELECT vwqmajorchargelists.accountnumber AS chargeaccount, vwqmajorchargelists.accountcode, 
		vwqmajorchargelists.chargetypename, vwqmajorchargelists.quarterid, vwqmajorchargelists.studylevel, 
		vwqmajorchargelists.majorid, vwqmajorchargelists.majorname, 
		vwqmajorchargelists.sublevelid, vwqmajorchargelists.sublevelname,
        CASE WHEN vwqstudentbalances.offcampus = true THEN vwqmajorchargelists.nonresident
            WHEN vwqstudentbalances.mealtype::text = 'BLS'::text THEN vwqmajorchargelists.threemeals
            ELSE vwqmajorchargelists.regural END AS unitfees, 
		vwqstudentbalances.accountnumber, vwqstudentbalances.studentname, vwqstudentbalances.fees, 
		vwqstudentbalances.residencecharge, vwqstudentbalances.picked, vwqstudentbalances.qstudentid,
		vwqstudentbalances.mealtype
	FROM vwqmajorchargelists JOIN vwqstudentbalances ON vwqmajorchargelists.majorid::text = vwqstudentbalances.majorid::text AND vwqmajorchargelists.studylevel = vwqstudentbalances.studylevel AND vwqmajorchargelists.quarterid::text = vwqstudentbalances.quarterid::text
	WHERE (vwqstudentbalances.finaceapproval = true)
	ORDER BY vwqstudentbalances.accountnumber;

CREATE OR REPLACE FUNCTION ins_qorg_id() RETURNS trigger AS $$
BEGIN
	SELECT org_id INTO NEW.org_id
	FROM quarters
	WHERE (quarterid = NEW.quarterid);
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ins_qorg_id BEFORE INSERT OR UPDATE
  ON qcharges FOR EACH ROW EXECUTE PROCEDURE ins_qorg_id();
CREATE TRIGGER ins_qorg_id BEFORE INSERT OR UPDATE
  ON qmcharges FOR EACH ROW EXECUTE PROCEDURE ins_qorg_id();
CREATE TRIGGER ins_qorg_id BEFORE INSERT OR UPDATE
  ON qchargedefinations FOR EACH ROW EXECUTE PROCEDURE ins_qorg_id();
CREATE TRIGGER ins_qorg_id BEFORE INSERT OR UPDATE
  ON qmchargedefinations FOR EACH ROW EXECUTE PROCEDURE ins_qorg_id();



