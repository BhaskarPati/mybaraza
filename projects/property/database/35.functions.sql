CREATE OR REPLACE FUNCTION tenant_notifications(varchar(12), varchar(12), varchar(12),varchar(12)) RETURNS varchar(120) AS $$
	DECLARE
		msg				varchar(120);
	BEGIN
		IF($3::integer = 1)THEN
			INSERT INTO sys_emailed (sys_email_id, table_id, table_name, email_type) VALUES (1, $1::integer, 'entitys', 3);
			msg := 'Tenant Rent Adjustment email sent';
		END IF;

		IF($3::integer = 2)THEN
			INSERT INTO sys_emailed (sys_email_id, table_id, table_name, email_type) VALUES (2, $1::integer, 'entitys', 3);
			msg := 'Release of bills/invoices email sent';
		END IF;

		IF($3::integer = 3)THEN
			INSERT INTO sys_emailed (sys_email_id, table_id, table_name, email_type) VALUES (3, $1::integer, 'entitys', 3);
			msg := 'Overdue Payment email sent';
		END IF;

		IF($3::integer = 4)THEN
			INSERT INTO sys_emailed (sys_email_id, table_id, table_name, email_type) VALUES (4, $1::integer, 'entitys', 3);
			msg := 'Release for contracts/rental agreements email sent';
		END IF;
RETURN msg;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION un_archive (varchar(12), varchar(12), varchar(12),varchar(12)) RETURNS varchar(120) AS $$
	DECLARE
		msg				varchar(120);
	BEGIN
		IF($3::integer = 1)THEN
			UPDATE entitys SET is_active = true WHERE entity_id = $1::int;
		msg := 'Activated';
		END IF;

		IF($3::integer = 2)THEN
			UPDATE property SET is_active = true WHERE property_id = $1::int;
		msg := 'Activated';
		END IF;
		
RETURN msg;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_total_remit(integer) RETURNS integer AS $$
    SELECT COALESCE(sum(rental_amount), 0)::integer
	FROM period_rentals
	WHERE (status='Draft') AND (property_id = $1);
$$ LANGUAGE SQL;




