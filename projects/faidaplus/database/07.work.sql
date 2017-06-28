


----------- Do an anlysis for the Travelport ticket report
SELECT a.runtyp, a.pcc, a.s_segs, b.total_segs

FROM (SELECT runtyp, pcc, sum(acttxnet) as s_segs
FROM imp_segs
GROUP BY runtyp, pcc) a LEFT JOIN
(SELECT ('M' || vwtickets.segperiod) as seg_period, vwtickets.ticketpcc, 
	sum(vwtickets.activesegs) as total_segs
FROM vwtickets
GROUP BY vwtickets.segperiod, vwtickets.ticketpcc) b
ON (a.runtyp = b.seg_period) AND (a.pcc = b.ticketpcc);


--------- run balances
SELECT a.pcc, a.org_name, a.entity_id, b.entity_name, to_char(sum(balance), '999,999,999,999')
FROM vw_son_statement a INNER JOIN entitys b ON a.entity_id = b.entity_id
GROUP BY a.pcc, a.org_name, a.entity_id, b.entity_name
ORDER BY sum(balance) desc;


---- Do a balance analysis
SELECT entity_id, entity_name, sum(balance)
FROM vw_opening_balance
---WHERE order_date < '2016-01-01'::date
GROUP BY entity_id, entity_name
ORDER BY sum(balance)




---------------------- Balance update tasks
ALTER TABLE orders ADD org_entity_id integer;

SELECT a.org_id, a.org_name, a.pcc, a.entity_id, a.entity_name, a.son, to_char(b.bal, '999,9999,999,999')
FROM vw_entitys a INNER JOIN
(SELECT entity_id, sum(balance) as bal
FROM vw_son_statement
GROUP BY entity_id
HAVING sum(balance) < 0) b

ON a.entity_id = b.entity_id
ORDER BY b.bal DESC



SELECT q.entity_id, q.max_period_id, p.start_date 

FROM periods p INNER JOIN 
(SELECT po.entity_id, max(po.period_id) as max_period_id
FROM points po
WHERE po.entity_id IN (1401,2049,2044,1645,958,935,1439,1810,1067,1372,1873,139,1395,2033,229,1588,393,486,2259,1293,1165,1328,1996,1967)
GROUP BY po.entity_id) q
ON p.period_id = q.max_period_id

ORDER BY q.entity_id;


SELECT points_id, org_id, entity_id, period_id, point_date, pcc, son, segments, amount, points, bonus
FROM points
WHERE entity_id = 0 and period_id = 110
ORDER BY period_id;


SELECT points_id, org_id, entity_id, period_id, point_date, pcc, son, segments, amount, points, bonus
FROM points
WHERE entity_id = 1967 
ORDER BY period_id;


UPDATE points SET entity_id = 2437, org_entity_id = 0 WHERE points_id = 1851989;

