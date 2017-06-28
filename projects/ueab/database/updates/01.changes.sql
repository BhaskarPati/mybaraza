CREATE OR REPLACE FUNCTION getdbgradeid(integer) RETURNS varchar(2) AS $$
	SELECT CASE WHEN max(gradeid) is null THEN 'NG' WHEN $1 = -1 THEN 'DG' ELSE max(gradeid) END
	FROM grades 
	WHERE (minrange <= $1) AND (maxrange > $1);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION getPGgradeid(integer) RETURNS varchar(2) AS $$
	SELECT CASE WHEN max(gradeid) is null THEN 'NG' WHEN $1 = -1 THEN 'DG' ELSE max(gradeid) END
	FROM grades 
	WHERE (p_minrange <= $1) AND (p_maxrange > $1);
$$ LANGUAGE SQL;



CREATE TABLE countys(

county_id		char(2) primary key,
county_name		varchar(50)


);

ALTER TABLE students 
ADD COLUMN disability varchar(5),
ADD COLUMN dis_details text,
ADD COLUMN county_id char(2) references countys,
ADD COLUMN passport boolean DEFAULT false,
ADD COLUMN national_id  boolean DEFAULT false,
ADD COLUMN identification_no varchar(20);


CREATE INDEX students_county_id ON students (county_id);

INSERT INTO countys(county_id, county_name)
VALUES	('MO', 'Mombasa'),
		('KW','Kwale'),
		('KI','Kilifi'),
		('TR','Tana River'),
		('LA','Lamu'),
		('TT','Taita-Taveta'),
		('GA','Garissa'),
		('WA','Wajir'),
		('MA','Mandera'),
		('MR','Marsabit'),
		('IS','Isiolo'),
		('ME','Meru'),
		('TN','Tharaka-Nithi'),
		('EB','Embu'),
		('KT','Kitui'),
		('MC','Machakos'),
		('MK','Makueni'),
		('NY','Nyandarua'),
		('NR','Nyeri'),
		('KR','Kirinyaga'),
		('MU','Muranga'),
		('KB','Kiambu'),
		('TK','Turkana'),
		('WP','West Pokot'),
		('SA','Samburu'),
		('TZ','Trans Nzoia'),
		('UG','Uasin Gishu'),
		('EM','Elgeyo-Marakwet'),
		('ND','Nandi'),
		('BR','Baringo'),
		('LP','Laikipia'),
		('NK','Nakuru'),
		('NO','Narok'),
		('KJ','kajiado'),
		('BM','Bomet'),
		('BU','Bungoma'),
		('BS','Busia'),
		('HO','Homabay'),
		('KA','Kakamega'),
		('KE','Kericho'),
		('KS','Kisii'),
		('KU','Kisumu'),
		('MI','Migori'),
		('MS','Marsabit'),
		('NI','Nairobi'),
		('NM','Nyamira'),
		('SI','Siaya'),
		('VI','Vihiga');
		
	



UPDATE sys_emails SET details = 'Dear {{name}},<br/><br/>

Thank you for applying to the University of Eastern Africa, Baraton.<br/>
To access form online use the the following information:<br/>
Username: {{username}} Password: {{password}}<br/><br/>


Go to http://registration.ueab.ac.ke/a_admissions.jsp<br/>
Using this link login with your username and password to complete your application.<br/>
Note: You can "Save" your application, and continue later until you are ready to "Complete and Exit".<br/>


Regards,<br/>
Admissions Office<br/>
University of Eastern Africa, Baraton<br/>
Eldoret<br/>
(254) 053-522625<br/>
admissions@ueab.ac.ke<br/>';

    
 ALTER TABLE quarters
 ADD COLUMN dean_cert_date date default null,
 ADD COLUMN hon_cert_date date default null,
 ADD COLUMN grad_date date default null;
 
 CREATE OR REPLACE VIEW studentcounty AS
SELECT students.county_id, students.studentid, countys.county_name
FROM students
INNER JOIN countys ON students.county_id=countys.county_id;
 
 CREATE OR REPLACE VIEW qstudentviewc AS
SELECT q.religionid, q.religionname, q.denominationid, q.denominationname, q.schoolid, 
       q.schoolname, q.studentid, q.studentname, q.address, q.zipcode, q.town, q.addresscountry, 
       q.telno, q.email, q.guardianname, q.gaddress, q.gzipcode, q.gtown, q.gaddresscountry, 
       q.gtelno, q.gemail, q.accountnumber, q.nationality, q.nationalitycountry, 
       q.sex, q.maritalstatus, q.birthdate, q.firstpass, q.alumnae, q.postcontacts, 
       q.onprobation, q.offcampus, q.currentcontact, q.currentemail, q.currenttel, 
       q.freshman, q.sophomore, q.junior, q.senior, q.degreeid, q.degreename, q.studentdegreeid, 
       q.completed, q.started, q.cleared, q.clearedate, q.graduated, q.graduatedate, 
       dropout, transferin, transferout, mathplacement, englishplacement, 
       quarterid, qstart, qlatereg, qlatechange, qlastdrop, qend, active, 
       chalengerate, feesline, resline, quarteryear, quarter, closed, 
       q.quarter_name, q.degreelevelid, q.degreelevelname, q.charge_id, q.unit_charge, 
       q.lab_charges, q.exam_fees, q.levellocationid, q.levellocationname, q.sublevelid, 
       q.sublevelname, q.specialcharges, q.sun_posted, q.session_active, q.session_closed, 
       q.general_fees, q.residence_stay, q.currency, q.exchange_rate, q.residenceid, 
       q.residencename, q.capacity, q.defaultrate, q.residenceoffcampus, q.residencesex, 
       q.residencedean, q.qresidenceid, q.residenceoption, q.org_id, q.qstudentid, 
       q.additionalcharges, q.approved, q.probation, q.roomnumber, q.currbalance, 
       q.finaceapproval, q.majorapproval, q.studentdeanapproval, q.intersession, 
       q.exam_clear, q.exam_clear_date, q.exam_clear_balance, q.request_withdraw, 
      q.request_withdraw_date, q.withdraw, q.ac_withdraw, q.withdraw_date, 
       q.withdraw_rate, q.departapproval, q.overloadapproval, q.finalised, q.printed, 
       q.details, q.ucharge, q.residencecharge, q.lcharge, q.feescharge,studentcounty.county_name,studentcounty.county_id
  FROM qstudentview as q
  INNER JOIN studentcounty ON q.studentid= studentcounty.county_id ;
  
  
  
   CREATE OR REPLACE VIEW qstudentviewid AS 
	SELECT
	qstudentview.denominationname,
	qstudentview.schoolname,
    qstudentview.studentid,
	qstudentview.studentname,
    qstudentview.nationalitycountry,
    qstudentview.sex,
    qstudentview.maritalstatus,
	qstudentview.degreename,
    qstudentview.studentdegreeid,
    qstudentview.quarterid,
    qstudentview.degreelevelname,
    qstudentview.sublevelname,
    qstudentview.approved,
	students.identification_no,
	students.passport,
	students.national_id,
	qstudentview.nationality
    FROM qstudentview
    INNER JOIN students ON qstudentview.studentid=students.studentid;
  
  

UPDATE fields SET question = 'Parent or Guardians commitment: I agree that the applicant may be a student at the University of Eastern Africa, Baraton. I am
ready to support the university in its effort to ensure that the applicant abides by the rules and principles of the university and
accepts the authority of its administration.'
WHERE field_id = 106;


UPDATE fields SET field_size = 150 WHERE field_id = 106;




   
