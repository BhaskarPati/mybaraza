CREATE OR REPLACE FUNCTION merge_org(integer, integer) RETURNS varchar(120) AS $$
DECLARE
	msg 			varchar(120);
BEGIN
	UPDATE court_payments SET org_id = $2 WHERE org_id = $1;
	UPDATE log_court_payments SET org_id = $2 WHERE org_id = $1;
	UPDATE log_receipts SET org_id = $2 WHERE org_id = $1;
	UPDATE receipts SET org_id = $2 WHERE org_id = $1;
	UPDATE log_case_contacts SET org_id = $2 WHERE org_id = $1;
	UPDATE case_contacts SET org_id = $2 WHERE org_id = $1;
	UPDATE log_case_activity SET org_id = $2 WHERE org_id = $1;
	UPDATE case_activity SET org_id = $2 WHERE org_id = $1;
	UPDATE log_cases SET org_id = $2 WHERE org_id = $1;
	UPDATE cases SET org_id = $2 WHERE org_id = $1;
	UPDATE address SET org_id = $2 WHERE org_id = $1;
	UPDATE entitys SET org_id = $2 WHERE org_id = $1;
	UPDATE entity_subscriptions SET org_id = $2 WHERE org_id = $1;
	UPDATE court_stations SET org_id = $2 WHERE org_id = $1;
	UPDATE bank_accounts SET org_id = $2 WHERE org_id = $1;
	UPDATE hearing_locations SET org_id = $2 WHERE org_id = $1;
	UPDATE court_divisions SET org_id = $2 WHERE org_id = $1;
	
	DELETE FROM orgs WHERE org_id = $1;

	msg := 'Changed';

	return msg;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER upd_receipts ON receipts;

SELECT merge_org(124, 103);
SELECT merge_org(142,104);
SELECT merge_org(135,121);
SELECT merge_org(136,107);
SELECT merge_org(129,108);
SELECT merge_org(143,109);
SELECT merge_org(163,110);
SELECT merge_org(153,112);
SELECT merge_org(139,114);
SELECT merge_org(137,116);
SELECT merge_org(145,115);
SELECT merge_org(127,117);
SELECT merge_org(123,119);


CREATE TRIGGER upd_receipts BEFORE INSERT OR UPDATE ON receipts
FOR EACH ROW EXECUTE PROCEDURE upd_receipts();


----------- Delete duplicate cases

CREATE OR REPLACE FUNCTION del_case(integer) RETURNS varchar(120) AS $$
DECLARE
	msg 			varchar(120);
BEGIN
	DELETE FROM log_court_payments WHERE receipt_id IN (SELECT receipt_id FROM receipts WHERE case_id = $1);
	DELETE FROM court_payments WHERE receipt_id IN (SELECT receipt_id FROM receipts WHERE case_id = $1);
	DELETE FROM log_receipts WHERE case_id = $1;
	DELETE FROM receipts WHERE case_id = $1;
	DELETE FROM log_case_contacts WHERE case_id = $1;
	DELETE FROM case_contacts WHERE case_id = $1;
	DELETE FROM log_case_activity WHERE case_id = $1;
	DELETE FROM case_activity WHERE case_id = $1;
	DELETE FROM log_cases WHERE case_id = $1;
	DELETE FROM cases WHERE case_id = $1;

	SELECT file_number INTO msg
	FROM cases WHERE case_id = $1;

	IF(msg is null)THEN
		msg := 'DELETED';
	END IF;

	return msg;
END;
$$ LANGUAGE plpgsql;

SELECT del_case(332);

SELECT del_case(233);
SELECT del_case(205);
SELECT del_case(229);

SELECT del_case(219);
SELECT del_case(217);

SELECT del_case(21);
SELECT del_case(80);
SELECT del_case(180);


SELECT del_case(88);
SELECT del_case(141);
SELECT del_case(186);
SELECT del_case(187);
SELECT del_case(53);
SELECT del_case(74);
SELECT del_case(163);
SELECT del_case(112);
SELECT del_case(104);
SELECT del_case(161);
SELECT del_case(167);
SELECT del_case(99);
SELECT del_case(140);
SELECT del_case(96);
SELECT del_case(166);
SELECT del_case(146);
SELECT del_case(154);
SELECT del_case(157);
SELECT del_case(127);
SELECT del_case(52);
SELECT del_case(188);
SELECT del_case(189);
SELECT del_case(191);
SELECT del_case(20);
SELECT del_case(160);
SELECT del_case(159);
SELECT del_case(160);
SELECT del_case(119);

SELECT del_case(246);

------------Show cases with EL on the number instead of court station

SELECT court_station, file_number, case_title 
FROM vw_cases
WHERE file_number ilike '%EL%' and court_station_id != 105


------------ Realign the org_id of cases

DROP TRIGGER upd_receipts ON receipts;

UPDATE cases SET org_id = court_divisions.org_id FROM court_divisions
WHERE cases.court_division_id = court_divisions.court_division_id;

UPDATE case_activity SET org_id = cases.org_id FROM cases
WHERE case_activity.case_id = cases.case_id;

UPDATE case_contacts SET org_id = cases.org_id FROM cases
WHERE case_contacts.case_id = cases.case_id;

UPDATE case_files SET org_id = cases.org_id FROM cases
WHERE case_files.case_id = cases.case_id;

UPDATE receipts SET org_id = cases.org_id FROM cases
WHERE receipts.case_id = cases.case_id;

UPDATE court_payments SET org_id = receipts.org_id FROM receipts
WHERE court_payments.receipt_id = receipts.receipt_id;

CREATE TRIGGER upd_receipts BEFORE INSERT OR UPDATE ON receipts
FOR EACH ROW EXECUTE PROCEDURE upd_receipts();


