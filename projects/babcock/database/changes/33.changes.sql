

UPDATE sublevels SET org_id = 0 WHERE org_id is null;
ALTER TABLE sublevels ALTER COLUMN org_id SET NOT NULL;

UPDATE courses SET degreelevelid = 'MAS' WHERE degreelevelid = 'MSC';
UPDATE sublevels SET degreelevelid = 'MAS' WHERE degreelevelid = 'MSC';
DELETE FROM qcharges WHERE degreelevelid = 'MSC';
DELETE FROM sublevels WHERE degreelevelid = 'MSC';
DELETE FROM degreelevels WHERE degreelevelid = 'MSC';

UPDATE courses SET degreelevelid = 'MAS' WHERE degreelevelid = 'MA';
UPDATE sublevels SET degreelevelid = 'MAS' WHERE degreelevelid = 'MA';
UPDATE degrees SET degreelevelid = 'MAS' WHERE degreelevelid = 'MA';
DELETE FROM qcharges WHERE degreelevelid = 'MA';
DELETE FROM sublevels WHERE degreelevelid = 'MA';
DELETE FROM degreelevels WHERE degreelevelid = 'MA';

UPDATE courses SET degreelevelid = 'PHD' WHERE degreelevelid = 'MPhi/PhD';
UPDATE sublevels SET degreelevelid = 'PHD' WHERE degreelevelid = 'MPhi/PhD';
UPDATE degrees SET degreelevelid = 'PHD' WHERE degreelevelid = 'MPhi/PhD';
DELETE FROM qcharges WHERE degreelevelid = 'MPhi/PhD';
DELETE FROM sublevels WHERE degreelevelid = 'MPhi/PhD';
DELETE FROM degreelevels WHERE degreelevelid = 'MPhi/PhD';

INSERT INTO degreelevels (degreelevelid, org_id, degreelevelname) VALUES ('MPH', 2, 'Master of Philosoph');
UPDATE courses SET degreelevelid = 'MPH' WHERE degreelevelid = 'MPhil';
UPDATE sublevels SET degreelevelid = 'MPH' WHERE degreelevelid = 'MPhil';
UPDATE degrees SET degreelevelid = 'MPH' WHERE degreelevelid = 'MPhil';
DELETE FROM qcharges WHERE degreelevelid = 'MPhil';
DELETE FROM sublevels WHERE degreelevelid = 'MPhil';
DELETE FROM degreelevels WHERE degreelevelid = 'MPhil';
UPDATE degreelevels SET degreelevelname = 'Master of Philosophy' WHERE degreelevelid = 'MPH';

DELETE FROM entity_subscriptions WHERE entity_id = 29185;
DELETE FROM entitys WHERE entity_id = 29185;

UPDATE studentdegrees SET completed = true WHERE (studentdegreeid IN
	(SELECT studentdegrees.studentdegreeid
	FROM pg_elong INNER JOIN studentdegrees ON pg_elong.MAT_NO = studentdegrees.studentid
	WHERE (studentdegrees.org_id = 2) AND (pg_elong.MODULE = 'GRADUATED')));

UPDATE studentdegrees SET completed = true WHERE (studentdegreeid IN
	(SELECT studentdegrees.studentdegreeid
	FROM pg_elong INNER JOIN studentdegrees ON pg_elong.MAT_NO = studentdegrees.studentid
	WHERE (studentdegrees.org_id = 2) AND (pg_elong.MODULE = 'DROPPED OUT')));

UPDATE studentdegrees SET sublevelid = 'PHDE' WHERE (studentdegreeid IN
	(SELECT studentdegrees.studentdegreeid
	FROM pg_elong INNER JOIN studentdegrees ON pg_elong.MAT_NO = studentdegrees.studentid
	WHERE (studentdegrees.org_id = 2) AND (studentdegrees.sublevelid = 'PHD') AND (pg_elong.MODULE = 'ELONGATED')));

UPDATE studentdegrees SET sublevelid = 'PHDE' WHERE (studentdegreeid IN
	(SELECT studentdegrees.studentdegreeid
	FROM pg_elong INNER JOIN studentdegrees ON pg_elong.MAT_NO = studentdegrees.studentid
	WHERE (studentdegrees.org_id = 2) AND (studentdegrees.sublevelid = 'PHD') AND (pg_elong.MODULE = 'ELONGATED')));

UPDATE studentdegrees SET sublevelid = 'MASE' WHERE (studentdegreeid IN
	(SELECT studentdegrees.studentdegreeid
	FROM pg_elong INNER JOIN studentdegrees ON pg_elong.MAT_NO = studentdegrees.studentid
	WHERE (studentdegrees.org_id = 2) AND (studentdegrees.sublevelid = 'MAST') AND (pg_elong.MODULE = 'ELONGATED')));

INSERT INTO sublevels (sublevelid, degreelevelid, levellocationid, org_id, sublevelname) VALUES ('PGDE', 'PGD', 1, 2, 'Post Graduate Diploma - Elongated');

UPDATE studentdegrees SET sublevelid = 'PGDE' WHERE (studentdegreeid IN
	(SELECT studentdegrees.studentdegreeid
	FROM pg_elong INNER JOIN studentdegrees ON pg_elong.MAT_NO = studentdegrees.studentid
	WHERE (studentdegrees.org_id = 2) AND (studentdegrees.sublevelid = 'PGDI') AND (pg_elong.MODULE = 'ELONGATED')));


DROP VIEW sublevelview CASCADE;


UPDATE majors SET degreelevelid = 'UND' WHERE majorid = 'ANAT';
UPDATE majors SET degreelevelid = 'UND' WHERE majorid = 'BIOC';
UPDATE majors SET degreelevelid = 'UND' WHERE majorid = 'PHGY';

UPDATE studentmajors SET org_id = 0 WHERE majorid = 'ANAT';
UPDATE studentmajors SET org_id = 0 WHERE majorid = 'BIOC';
UPDATE studentmajors SET org_id = 0 WHERE majorid = 'PHGY';

UPDATE studentdegrees SET sublevelid = 'UNDM' WHERE studentdegreeid IN 
(SELECT studentdegreeid FROM studentmajors WHERE majorid = 'ANAT');
UPDATE studentdegrees SET sublevelid = 'UNDM' WHERE studentdegreeid IN 
(SELECT studentdegreeid FROM studentmajors WHERE majorid = 'BIOC');
UPDATE studentdegrees SET sublevelid = 'UNDM' WHERE studentdegreeid IN 
(SELECT studentdegreeid FROM studentmajors WHERE majorid = 'PHGY');

UPDATE qmcharges SET sublevelid = 'UNDM' WHERE majorid = 'ANAT';
UPDATE qmcharges SET sublevelid = 'UNDM' WHERE majorid = 'BIOC';
UPDATE qmcharges SET sublevelid = 'UNDM' WHERE majorid = 'PHGY';

UPDATE qmchargedefinations SET sublevelid = 'UNDM' WHERE majorid = 'ANAT';
UPDATE qmchargedefinations SET sublevelid = 'UNDM' WHERE majorid = 'BIOC';
UPDATE qmchargedefinations SET sublevelid = 'UNDM' WHERE majorid = 'PHGY';

UPDATE studentdegrees SET org_id = 0 WHERE studentdegreeid IN 
(SELECT studentdegreeid FROM studentmajors WHERE majorid = 'ANAT');
UPDATE studentdegrees SET org_id = 0 WHERE studentdegreeid IN 
(SELECT studentdegreeid FROM studentmajors WHERE majorid = 'BIOC');
UPDATE studentdegrees SET org_id = 0 WHERE studentdegreeid IN 
(SELECT studentdegreeid FROM studentmajors WHERE majorid = 'PHGY');

