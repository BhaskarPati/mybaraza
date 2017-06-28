ALTER TABLE entitys ADD no_org boolean;
UPDATE entitys SET org_id = 0 WHERE org_id is null;
UPDATE entitys SET entity_type_id = 2 WHERE entity_type_id is null;

DELETE FROM case_contacts WHERE (case_id IN (select case_id from cases where case_title is null));
DELETE FROM case_transfers WHERE (case_id IN (select case_id from cases where case_title is null));

DELETE FROM case_history where case_id in (select case_id from cases where case_title is null);
DELETE FROM cases where case_title is null;

DELETE FROM case_contacts WHERE (case_contact_id IN 
	(SELECT max(a.case_contact_id)
	FROM case_contacts as a,
		(SELECT entity_id, case_id
		FROM case_contacts
		GROUP BY entity_id, case_id
		HAVING count(case_contact_id) > 1) as b
		WHERE (a.entity_id = b.entity_id) AND (a.case_id = b.case_id)
	GROUP BY a.entity_id, a.case_id));


DELETE FROM case_contacts WHERE (case_contact_id IN 
	(SELECT max(a.case_contact_id)
	FROM case_contacts as a,
		(SELECT entity_id, case_id
		FROM case_contacts
		GROUP BY entity_id, case_id
		HAVING count(case_contact_id) > 1) as b
		WHERE (a.entity_id = b.entity_id) AND (a.case_id = b.case_id)
	GROUP BY a.entity_id, a.case_id));


