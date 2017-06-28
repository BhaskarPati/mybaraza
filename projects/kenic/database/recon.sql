--- get all records from epp database
SELECT id, client_roid, description, currency, round((tax / 100), 4) as calctax, total, 
	cast(created as date) as created_date, get_exdate(id) as expiry_date, 
	CASE WHEN previous_expiry_date is null THEN cast(created as date) ELSE cast(previous_expiry_date as date) END as previous_expiry, 
	trans_type, refund_for_id, documentnumber, get_ChequeNo(id) as ChequeNo 
FROM ledger
WHERE (cast(created as date) >= '2011-01-01')
ORDER BY id;

SELECT count(id)
FROM ledger
WHERE (cast(created as date) >= '2011-01-01');


--- mysql create comparison ledger
CREATE TABLE ledger_cmp (
	id				integer primary key, 
	client_roid		varchar(16), 
	description		varchar(240), 
	currency		varchar(3),
	tax				real, 
	total			real, 
	created			date, 
	exdate			date,
	previous_expiry_date	date,
	months_posted	integer default 0,
	trans_type		varchar(32),
	refund_for_id	integer,
	documentnumber	integer,
	ChequeNo		varchar(50)
);

INSERT INTO ledger_cmp (id, client_roid, description, currency, tax, total, created, exdate, previous_expiry_date, trans_type, refund_for_id, documentnumber, ChequeNo) VALUES (

--- count check
(SELECT count(id) FROM ledger_cmp)
UNION
(SELECT count(id) FROM ledger)
UNION
(SELECT count(ledger_cmp.id) FROM ledger_cmp LEFT JOIN ledger ON ledger_cmp.id = ledger.id)
UNION
(SELECT count(ledger.id) FROM ledger LEFT JOIN ledger_cmp ON ledger.id = ledger_cmp.id)

--- invoice check
SELECT *
FROM (SELECT * FROM ledger WHERE (trans_type = 'Application') OR (trans_type = 'Registration') OR (trans_type = 'Renewal')) as a
LEFT JOIN (SELECT * FROM debtor_trans WHERE type = 13) as b
	ON a.documentnumber = b.trans_no
WHERE (a.total <> 0) and (b.trans_no is null);


SELECT *
FROM (SELECT * FROM ledger WHERE (trans_type = 'Payment')) as a
LEFT JOIN (SELECT * FROM debtor_trans WHERE type = 12) as b
	ON a.documentnumber = b.trans_no
WHERE (a.total <> 0) and (b.trans_no is null);

SELECT *
FROM (SELECT * FROM ledger WHERE (trans_type = 'Refund')) as a
LEFT JOIN (SELECT * FROM debtor_trans WHERE type = 11) as b
	ON a.documentnumber = b.trans_no
WHERE (a.total <> 0) and (b.trans_no is null);


