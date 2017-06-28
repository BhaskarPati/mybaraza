
CREATE OR REPLACE FUNCTION replace_quarter(varchar(12), varchar(12)) RETURNS varchar(50) AS $$
DECLARE
    myrec RECORD;
	pass boolean;
BEGIN

	DELETE FROM qresidences WHERE quarterid = $2;

	UPDATE qcalendar SET quarterid = $2 WHERE quarterid = $1; 
	UPDATE qresidences SET quarterid = $2 WHERE quarterid = $1; 
	UPDATE qcharges SET quarterid = $2 WHERE quarterid = $1; 
	UPDATE qmcharges SET quarterid = $2 WHERE quarterid = $1; 
	UPDATE qchargedefinations SET quarterid = $2 WHERE quarterid = $1; 
	UPDATE qmchargedefinations SET quarterid = $2 WHERE quarterid = $1; 
	UPDATE qstudents SET quarterid = $2 WHERE quarterid = $1; 
	UPDATE qcourses SET quarterid = $2 WHERE quarterid = $1; 
	
	DELETE FROM quarters WHERE quarterid = $1; 

    RETURN 'Updated';
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION replace_qstudent(int, int) RETURNS varchar(50) AS $$
BEGIN
UPDATE qstudents SET studentdegreeid = $1 WHERE studentdegreeid = $2 and studylevel < 600;
RETURN 'Updated';
END;
$$ LANGUAGE plpgsql;


SELECT replace_quarter('2010/2011.P', '2010/2011.1P');
SELECT replace_quarter('2011/2012.P', '2011/2012.1P');
SELECT replace_quarter('2012/2013.P', '2012/2013.1P');
SELECT replace_quarter('2013/2014.P', '2013/2014.1P');
SELECT replace_quarter('2014/2015.P', '2014/2015.1P');


SELECT replace_qstudent(20613, 57450);


DELETE FROM approvallist WHERE qstudentid IN
(SELECT qstudents.qstudentid 
FROM qstudents LEFT JOIN qgrades ON qstudents.qstudentid = qgrades.qstudentid
WHERE qgrades.qstudentid is null);


DELETE FROM qposting_logs WHERE qstudentid IN
(SELECT qstudents.qstudentid 
FROM qstudents LEFT JOIN qgrades ON qstudents.qstudentid = qgrades.qstudentid
WHERE qgrades.qstudentid is null);

DELETE FROM studentpayments WHERE (approved = false) AND (qstudentid IN
(SELECT qstudents.qstudentid 
FROM qstudents LEFT JOIN qgrades ON qstudents.qstudentid = qgrades.qstudentid
WHERE qgrades.qstudentid is null));


DELETE FROM qstudents WHERE qstudentid IN
(SELECT qstudents.qstudentid 
FROM (qstudents LEFT JOIN qgrades ON qstudents.qstudentid = qgrades.qstudentid)
LEFT JOIN studentpayments ON qstudents.qstudentid = studentpayments.qstudentid
WHERE (qgrades.qstudentid is null)
AND (studentpayments.approved is null or studentpayments.approved = false));


SELECT a.studentid, a.studentdegreeid, b.studentdegreeid, replace_qstudent(a.studentdegreeid, b.studentdegreeid)

FROM
(SELECT studentdegrees.studentid, studentdegrees.studentdegreeid
FROM sublevels INNER JOIN studentdegrees ON sublevels.sublevelid = studentdegrees.sublevelid
WHERE (sublevels.org_id = 0)
AND (studentdegrees.studentid IN ('03/0672', '03/0707', '03/0732', '03/0745', '03/0869', '03/0900', '04/0009', '04/0021', '04/0089', '04/0089', '04/0134', '04/0165', '04/0195', '04/0225', '04/0298', '04/0453', '04/0532', '04/0588', '04/0592', '04/0654', '04/0661', '04/0766', '04/0776', '04/0837', '04/1007', '05/0002', '05/0004', '05/0010', '05/0027', '05/0065', '05/0071', '05/0147', '05/0172', '05/0172', '05/0223', '05/0288', '05/0308', '05/0327', '05/0405', '05/0412', '05/0418', '05/0443', '05/0448', '05/0456', '05/0468', '05/0491', '05/0495', '05/0498', '05/0509', '05/0516', '05/0528', '05/0665', '05/0665', '05/0806', '05/0811', '05/0843', '05/0890', '05/0931', '05/0937', '06/0012', '06/0020', '06/0020', '06/0035', '06/0106', '06/0108', '06/0187', '06/0203', '06/0322', '06/0412', '06/0487', '06/0509', '06/0567', '06/0581', '06/0588', '06/0620', '06/0623', '06/0635', '06/0648', '06/0668', '06/0668', '06/0703', '06/0712', '06/0835', '06/0843', '06/0955', '06/0984', '06/0984', '06/1002', '06/1033', '06/1068', '06/1093', '06/1107', '06/1148', '06/1194', '06/1209', '06/1220', '06/1256', '07/0066', '07/0070', '07/0079', '07/0119', '07/0126', '07/0137', '07/0186', '07/0205', '07/0209', '07/0259', '07/0295', '07/0316', '07/0352', '07/0374', '07/0403', '07/0477', '07/0480', '07/0489', '07/0505', '07/0517', '07/0532', '07/0559', '07/0595', '07/0702', '07/0702', '07/0770', '07/0827', '07/0892', '07/0892', '07/0922', '07/0952', '07/0986', '07/1116', '07/1126', '07/1130', '07/1130', '07/1177', '07/1179', '07/1185', '07/1197', '07/1211', '07/1246', '07/1255', '07/1306', '07/1388', '07/1465', '07/1484', '08/0014', '08/0024', '08/0048', '08/0052', '08/0132', '08/0174', '08/0206', '08/0212', '08/0227', '08/0279', '08/0397', '08/04089', '08/0409', '08/0482', '08/0520', '08/0523', '08/0524', '08/0666', '08/0668', '08/0700', '08/0708', '08/0852', '08/0853', '08/0943', '08/0975', '08/0998', '08/1055', '08/1100', '08/1102', '08/1172', '08/1250', '08/1289', '08/1346', '08/1363', '08/1489', '08/1622', '08/1622', '08/1640', '08/1669', '08/1898', '08/2048', '09/0021', '09/0032', '09/0062', '09/0180', '09/0282', '09/0304', '09/0825', '09/0852', '09/1016', '09/1193', '09/1759', '09/1808', '09/1903', '09/1906', '09/2171', '09/2224', '09/2479', '09/2677', '09/2881', '10/0186', '10/3173', '10/3190', '11/14324', '11/4259', '11/4261', '11/4263', '11/4264', '11/4272', '11/4278', '11/4279', '11/4283', '11/4289', '11/4292', '11/4293', '11/4299', '11/4306', '11/4315', '11/4317', '11/4322', '11/4323', '11/4324', '11/4325', '11/4329', '11/4332', '11/4365', '12/3806', '12/3807', '12/3808', '12/3809', '12/3815', '12/3819', '12/4267'))) as a
INNER JOIN
(SELECT studentdegrees.studentid, studentdegrees.studentdegreeid
FROM sublevels INNER JOIN studentdegrees ON sublevels.sublevelid = studentdegrees.sublevelid
WHERE (sublevels.org_id = 2)
AND (studentdegrees.studentid IN ('03/0672', '03/0707', '03/0732', '03/0745', '03/0869', '03/0900', '04/0009', '04/0021', '04/0089', '04/0089', '04/0134', '04/0165', '04/0195', '04/0225', '04/0298', '04/0453', '04/0532', '04/0588', '04/0592', '04/0654', '04/0661', '04/0766', '04/0776', '04/0837', '04/1007', '05/0002', '05/0004', '05/0010', '05/0027', '05/0065', '05/0071', '05/0147', '05/0172', '05/0172', '05/0223', '05/0288', '05/0308', '05/0327', '05/0405', '05/0412', '05/0418', '05/0443', '05/0448', '05/0456', '05/0468', '05/0491', '05/0495', '05/0498', '05/0509', '05/0516', '05/0528', '05/0665', '05/0665', '05/0806', '05/0811', '05/0843', '05/0890', '05/0931', '05/0937', '06/0012', '06/0020', '06/0020', '06/0035', '06/0106', '06/0108', '06/0187', '06/0203', '06/0322', '06/0412', '06/0487', '06/0509', '06/0567', '06/0581', '06/0588', '06/0620', '06/0623', '06/0635', '06/0648', '06/0668', '06/0668', '06/0703', '06/0712', '06/0835', '06/0843', '06/0955', '06/0984', '06/0984', '06/1002', '06/1033', '06/1068', '06/1093', '06/1107', '06/1148', '06/1194', '06/1209', '06/1220', '06/1256', '07/0066', '07/0070', '07/0079', '07/0119', '07/0126', '07/0137', '07/0186', '07/0205', '07/0209', '07/0259', '07/0295', '07/0316', '07/0352', '07/0374', '07/0403', '07/0477', '07/0480', '07/0489', '07/0505', '07/0517', '07/0532', '07/0559', '07/0595', '07/0702', '07/0702', '07/0770', '07/0827', '07/0892', '07/0892', '07/0922', '07/0952', '07/0986', '07/1116', '07/1126', '07/1130', '07/1130', '07/1177', '07/1179', '07/1185', '07/1197', '07/1211', '07/1246', '07/1255', '07/1306', '07/1388', '07/1465', '07/1484', '08/0014', '08/0024', '08/0048', '08/0052', '08/0132', '08/0174', '08/0206', '08/0212', '08/0227', '08/0279', '08/0397', '08/04089', '08/0409', '08/0482', '08/0520', '08/0523', '08/0524', '08/0666', '08/0668', '08/0700', '08/0708', '08/0852', '08/0853', '08/0943', '08/0975', '08/0998', '08/1055', '08/1100', '08/1102', '08/1172', '08/1250', '08/1289', '08/1346', '08/1363', '08/1489', '08/1622', '08/1622', '08/1640', '08/1669', '08/1898', '08/2048', '09/0021', '09/0032', '09/0062', '09/0180', '09/0282', '09/0304', '09/0825', '09/0852', '09/1016', '09/1193', '09/1759', '09/1808', '09/1903', '09/1906', '09/2171', '09/2224', '09/2479', '09/2677', '09/2881', '10/0186', '10/3173', '10/3190', '11/14324', '11/4259', '11/4261', '11/4263', '11/4264', '11/4272', '11/4278', '11/4279', '11/4283', '11/4289', '11/4292', '11/4293', '11/4299', '11/4306', '11/4315', '11/4317', '11/4322', '11/4323', '11/4324', '11/4325', '11/4329', '11/4332', '11/4365', '12/3806', '12/3807', '12/3808', '12/3809', '12/3815', '12/3819', '12/4267'))) as b
ON a.studentid = b.studentid

ORDER BY a.studentid;


SELECT a.studentid, a.studentdegreeid, b.studentdegreeid, replace_qstudent(a.studentdegreeid, b.studentdegreeid)

FROM
(SELECT studentdegrees.studentid, studentdegrees.studentdegreeid
FROM sublevels INNER JOIN studentdegrees ON sublevels.sublevelid = studentdegrees.sublevelid
WHERE (sublevels.org_id = 0)) as a
INNER JOIN
(SELECT studentdegrees.studentid, studentdegrees.studentdegreeid
FROM sublevels INNER JOIN studentdegrees ON sublevels.sublevelid = studentdegrees.sublevelid
WHERE (sublevels.org_id = 2)) as b
ON a.studentid = b.studentid

ORDER BY a.studentid;


UPDATE studentdegrees SET completed = true, cleared	= true WHERE studentdegreeid IN 
(SELECT a.studentdegreeid

FROM
(SELECT studentdegrees.studentid, studentdegrees.studentdegreeid
FROM sublevels INNER JOIN studentdegrees ON sublevels.sublevelid = studentdegrees.sublevelid
WHERE (sublevels.org_id = 0)) as a
INNER JOIN
(SELECT studentdegrees.studentid, studentdegrees.studentdegreeid
FROM sublevels INNER JOIN studentdegrees ON sublevels.sublevelid = studentdegrees.sublevelid
WHERE (sublevels.org_id = 2)) as b
ON a.studentid = b.studentid

ORDER BY a.studentid);




