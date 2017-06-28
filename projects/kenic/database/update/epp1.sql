INSERT INTO audit.master (audit_user, audit_login) VALUES ('automation', 'automation');
UPDATE ledger SET ispicked = false
WHERE (cast(created as date) >= '2011-01-01') AND (trans_type = 'Refund');


INSERT INTO audit.master (audit_user, audit_login) VALUES ('automation', 'automation');
UPDATE ledger
SET tax = 16.00, tax_label = 'VAT'
WHERE (cast(created as date) >= '2011-01-01') AND (trans_type = 'Refund')
AND tax is null;

CREATE OR REPLACE FUNCTION get_exdate(int) RETURNS date AS $$
DECLARE
	expDate DATE;
	reca RECORD;
	recb RECORD;
BEGIN
	SELECT id, CAST(created as DATE) as create_date, CAST(exdate as DATE) as exp_date, trans_type, refund_for_id INTO reca
	FROM ledger
	WHERE (id = $1);

	expDate := reca.exp_date;
	IF(reca.trans_type = 'Refund') THEN
		SELECT id, created, (CAST(exdate as DATE) - CAST(created as DATE)) as exp_days INTO recb
		FROM ledger
		WHERE (id = reca.refund_for_id);

		expDate := reca.create_date + recb.exp_days;
	ELSIF(reca.trans_type = 'Application') THEN
		expDate := reca.create_date + interval '1 year';
	END IF;

	IF(expDate is null) THEN
		expDate := reca.create_date + interval '1 year';
	END IF;

	RETURN expDate;
END;
$$ LANGUAGE plpgsql;

