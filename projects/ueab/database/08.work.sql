--- Select which courses have not been allocated a charge
SELECT *
FROM qstudents
WHERE charge_id is null;


UPDATE entitys SET entity_password = md5('invent') WHERE entity_type_id = 9;


UPDATE studentdegrees SET bulletingid = 3
WHERE studentdegreeid IN
(SELECT studentdegreeid
FROM qstudents
GROUP BY studentdegreeid
HAVING min(quarterid) > '2012/2013.1');



--- Audit trail drill
SELECT * 
FROM audittrail, qgrades
WHERE (audittrail.tablename = 'qgrades')
AND (audittrail.recordid = qgrades.qgradeid::varchar)
AND (qgrades.qstudentid = 109367)
ORDER BY audittrail.changedate;


SELECT * 
FROM sys_audit_trail, qgrades
WHERE (sys_audit_trail.table_name = 'qgrades')
AND (sys_audit_trail.record_id = qgrades.qgradeid::varchar)
AND (qgrades.qstudentid = 109367)
ORDER BY sys_audit_trail.change_date;


