CREATE TABLE centers (
	center_id			varchar(12) primary key,
	center_name			varchar(120),
	details				text
);

ALTER TABLE instructors 
ADD		photo_file			varchar(120);

ALTER TABLE students
DROP 	adminision_basis,
ADD		children_number		integer, 
ADD		Spouse_name			varchar(120), 
ADD		Spouse_education	varchar(240),
ADD		Present_work		varchar(240),
ADD		old_town			varchar(50);

UPDATE students SET old_town = town;
ALTER TABLE students DROP 	town;
ALTER TABLE students ADD	town		varchar(100);
UPDATE students SET  town = old_town;
ALTER TABLE students DROP 	old_town;

ALTER TABLE studentdegrees
ADD 	admission_basis		varchar(240),
ADD		center_id			varchar(12) references centers;
CREATE INDEX studentdegrees_center_id ON studentdegrees (center_id);

ALTER TABLE scourses
ADD	old_scourseid	varchar(16);

ALTER TABLE scourses
ADD	center_id		varchar(12) references centers;
CREATE INDEX scourses_center_id ON scourses (center_id);

---SELECT setval('studentdegrees_studentdegreeid_seq', 151);
---SELECT setval('studentmajors_studentmajorid_seq', 181);
ALTER TABLE scourses DROP CONSTRAINT scourses_instructorid_key;

CREATE OR REPLACE FUNCTION getDataValue(varchar(16), varchar(16)) RETURNS varchar(240) AS $$
	SELECT trim(data_value) 
	FROM old_data_values
	WHERE (id_data = $1) AND (id_people = $2);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION getCountryID(varchar(240)) RETURNS char(2) AS $$
	SELECT countryid
	FROM countrys
	WHERE (trim(lower(countryname)) = trim(lower($1)));
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION getCenterID(varchar(240)) RETURNS char(16) AS $$
	SELECT max(name_short)
	FROM old_centers
	WHERE id_center = $1;
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION getstudentdegreeid(varchar(12)) RETURNS integer AS $$
    SELECT max(studentdegreeid) FROM studentdegrees WHERE (studentid = $1);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION getInstructorID(varchar(240)) RETURNS char(16) AS $$
	SELECT instructors.instructorid
	FROM instructors INNER JOIN old_teachers ON trim(lower(old_teachers.family_name || ', ' || old_teachers.first_name)) = trim(lower(instructors.instructorname))
	WHERE (old_teachers.id_people = $1);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION getSresidentid(varchar(12)) RETURNS int AS $$
	SELECT max(sresidences.sresidenceid) 
	FROM sresidences INNER JOIN sessions ON sresidences.sessionid =sessions.sessionid 
	WHERE (sresidences.residenceid = $1) AND (sessions.active = true);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION getSresidentid(varchar(12), varchar(12)) RETURNS int AS $$
	SELECT max(sresidenceid) 
	FROM sresidences 
	WHERE (residenceid = $1) AND (sessionid  = $2);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION getsstudentid(varchar(12)) RETURNS int AS $$
	SELECT max(sstudents.sstudentid) 
	FROM (studentdegrees INNER JOIN sstudents ON studentdegrees.studentdegreeid = sstudents.studentdegreeid)
		INNER JOIN sessions ON sstudents.sessionid = sessions.sessionid
	WHERE (studentdegrees.studentid = $1) AND (sessions.active = true);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION getsstudentid(varchar(12), varchar(12)) RETURNS int AS $$
	SELECT max(sstudents.sstudentid) 
	FROM studentdegrees INNER JOIN sstudents ON studentdegrees.studentdegreeid = sstudents.studentdegreeid
	WHERE (studentdegrees.studentid = $1) AND (sstudents.sessionid = $2);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION insScourses() RETURNS trigger AS $$
BEGIN
	NEW.coursetitle := getcoursetitle(NEW.courseid);
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER insScourses BEFORE INSERT ON scourses
    FOR EACH ROW EXECUTE PROCEDURE insScourses();

CREATE OR REPLACE FUNCTION updScourses() RETURNS trigger AS $$
BEGIN
	IF (OLD.courseid <> NEW.courseid) THEN
		NEW.coursetitle := getcoursetitle(NEW.courseid);
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER updScourses BEFORE UPDATE ON scourses
    FOR EACH ROW EXECUTE PROCEDURE updScourses();

CREATE OR REPLACE FUNCTION getcoursetitle(varchar(12)) RETURNS varchar(50) AS $$
	SELECT MAX(coursetitle) FROM courses WHERE (courseid = $1);
$$ LANGUAGE SQL;

