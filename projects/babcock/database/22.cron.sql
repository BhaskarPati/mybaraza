

--- Clear the 
UPDATE qstudents SET qresidenceid = null, financeclosed = false
FROM vwqstudentbalances 
WHERE (qstudents.finaceapproval = false) AND (age(qstudents.residence_time) > '1 day'::interval) AND (qstudents.offcampus = false)
	AND (qstudents.qresidenceid is not null) AND (qstudents.quarterid = vwqstudentbalances.quarterid)
	AND (qstudents.qstudentid = vwqstudentbalances.qstudentid) AND (vwqstudentbalances.finalbalance < 10000)
	AND (vwqstudentbalances.finaceapproval = false) AND (vwqstudentbalances.active = true);
