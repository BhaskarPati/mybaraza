

CREATE FUNCTION getcoremajor(varchar(12)) RETURNS varchar(75) AS $$
	SELECT max(majors.majorname)
	FROM studentmajors INNER JOIN majors ON studentmajors.majorid = majors.majorid
		INNER JOIN studentdegrees ON studentmajors.studentdegreeid = studentdegrees.studentdegreeid
	WHERE (studentdegrees.studentid = $1) AND (studentmajors.primarymajor = true);
$$ LANGUAGE sql;

SELECT cc.schoolid, cc.schoolname, cc.departmentid, cc.departmentname, cc.majorid, cc.majorname,
	sum(m1) as sm1, sum(f1) as sf1, sum(m2) as sm2, sum(f2) as sf2, sum(m3) as sm3, sum(f3) as sf3,
	sum(m4) as sm4, sum(f4) as sf4, sum(m5) as sm5, sum(f5) as sf5


FROM (SELECT majorview.schoolid, majorview.schoolname, majorview.departmentid, majorview.departmentname,
	majorview.majorid, majorview.majorname,
	aa.studentdegreeid, aa.first_quarter, aa.last_quarter, bb.total_credit, students.sex,
	
	(CASE WHEN students.sex = 'M' AND bb.total_credit <= 42 THEN 1 ELSE 0 END) as m1,
	(CASE WHEN students.sex = 'F' AND bb.total_credit <= 42 THEN 1 ELSE 0 END) as f1,
	
	(CASE WHEN students.sex = 'M' AND bb.total_credit > 42 AND bb.total_credit <= 84 THEN 1 ELSE 0 END) as m2,
	(CASE WHEN students.sex = 'F' AND bb.total_credit > 42 AND bb.total_credit <= 84 THEN 1 ELSE 0 END) as f2,
	
	(CASE WHEN students.sex = 'M' AND bb.total_credit > 84 AND bb.total_credit <= 106 THEN 1 ELSE 0 END) as m3,
	(CASE WHEN students.sex = 'F' AND bb.total_credit > 84 AND bb.total_credit <= 106 THEN 1 ELSE 0 END) as f3,
	
	(CASE WHEN students.sex = 'M' AND bb.total_credit > 106 AND bb.total_credit <= 144 THEN 1 ELSE 0 END) as m4,
	(CASE WHEN students.sex = 'F' AND bb.total_credit > 106 AND bb.total_credit <= 144 THEN 1 ELSE 0 END) as f4,
	
	(CASE WHEN students.sex = 'M' AND bb.total_credit > 144 THEN 1 ELSE 0 END) as m5,
	(CASE WHEN students.sex = 'F' AND bb.total_credit > 144 THEN 1 ELSE 0 END) as f5
	

FROM (SELECT studentdegreeid, min(quarterid) as first_quarter, max(quarterid) as last_quarter
	FROM qstudents
	WHERE (approved = true)
	GROUP BY studentdegreeid) aa
INNER JOIN
	(SELECT qstudents.studentdegreeid, sum(qgrades.credit) as total_credit
	FROM (qgrades INNER JOIN qstudents ON qgrades.qstudentid = qstudents.qstudentid)
		INNER JOIN grades ON qgrades.gradeid = grades.gradeid
	WHERE (qstudents.approved = true) AND (qgrades.dropped = false)
		AND (grades.gpacount = true) AND (qgrades.repeated = false) 
		AND (qgrades.gradeid <> 'W') AND (qgrades.gradeid <> 'AW')
	GROUP BY qstudents.studentdegreeid) bb
	ON aa.studentdegreeid = bb.studentdegreeid
INNER JOIN studentdegrees ON aa.studentdegreeid = studentdegrees.studentdegreeid
INNER JOIN students ON studentdegrees.studentid = students.studentid
INNER JOIN studentmajors ON aa.studentdegreeid = studentmajors.studentdegreeid
INNER JOIN majorview ON studentmajors.majorid = majorview.majorid

WHERE (studentmajors.primarymajor = true)  AND (bb.total_credit > 0)) cc

GROUP BY cc.schoolid, cc.schoolname, cc.departmentid, cc.departmentname, cc.majorid, cc.majorname

	

UPDATE sublevels SET max_credits = 18;

CREATE OR REPLACE FUNCTION getoverload(real, float, float, float, boolean, float) RETURNS boolean AS $$
DECLARE
	myoverload boolean;
BEGIN
	myoverload := false;

	IF ($1=18) THEN
		IF (($3<1.99) AND ($2<>9)) THEN
			myoverload := true;
		ELSIF ($3 is null) AND ($2 > 18) THEN
			myoverload := true;
		ELSIF (($4>=110) AND ($3>=2.70) AND ($2<=21)) THEN
			myoverload := false;
		ELSE
			IF (($3<3) AND ($2>18)) THEN
				myoverload := true;
			ELSIF (($3<3.5) AND ($2>19)) THEN
				myoverload := true;
			ELSIF ($2>20) THEN
				myoverload := true;
			END IF;
		END IF;
	ELSE
		IF($2 > $1)THEN
			myoverload := true;
		END IF;
	END IF;

	IF (myoverload = true) THEN
		IF ($5 = true) AND ($2 <= $6) THEN
			myoverload := false;
		END IF;
	END IF;

    RETURN myoverload;
END;
$$ LANGUAGE plpgsql;

