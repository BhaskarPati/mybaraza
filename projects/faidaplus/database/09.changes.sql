CREATE OR REPLACE FUNCTION generate_points(varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	rec						RECORD;
	v_period				varchar(7);
	period					date;
	v_start_date			date;
	v_increment				integer;
	v_period_id				integer;
	v_org_id				integer;
	v_entity_id				integer;
	v_points				real;
	v_points_id				integer;
	v_root_points			integer;
	v_amount				real;
	msg 					varchar(120);
BEGIN

	v_period_id = $1::integer;
	SELECT start_date, end_date, to_char(start_date, 'mmyyyy') INTO v_start_date, period, v_period
	FROM periods WHERE period_id = v_period_id AND closed = false;
	IF(v_period IS NULL)THEN RAISE EXCEPTION 'Period is closed'; END IF;

	IF(v_start_date < '2016-06-01'::date)THEN
		v_increment := 0;
	ELSE
		v_increment := 2;
	END IF;

	v_root_points := 0;
	DELETE FROM points WHERE period_id = v_period_id AND entity_id = 0;

	FOR rec IN SELECT pcc, son, bookpcc, ticketperiod, totalsegs, substring(bookpcc from 1 for 6) as svcb_son
		FROM t_sonsegs WHERE (ticketperiod = v_period) AND (totalsegs > 0)
	LOOP

		IF(1<= rec.totalsegs::integer AND rec.totalsegs::integer <=250 ) THEN
			v_amount := 12 + v_increment;
			v_points := rec.totalsegs * v_amount;
		END IF;

		IF(251<= rec.totalsegs::integer AND rec.totalsegs::integer <=500) THEN
			v_amount := 16 + v_increment;
			v_points := rec.totalsegs * v_amount;
		END IF;

		IF(rec.totalsegs::integer >=501 ) THEN
			v_amount := 20 + v_increment;
			v_points := rec.totalsegs * v_amount;
		END IF;

		SELECT orgs.org_id, entitys.entity_id INTO v_org_id, v_entity_id
		FROM orgs INNER JOIN entitys ON orgs.org_id = entitys.org_id
		WHERE (entitys.is_active = true) AND (orgs.pcc = rec.pcc) AND (entitys.son = rec.son);

		IF(v_entity_id is null)THEN
			SELECT entity_id INTO v_entity_id
			FROM change_pccs
			WHERE (approve_status = 'Approved') AND (pcc = rec.pcc) AND (son = rec.son);
			SELECT org_id INTO v_org_id
			FROM entitys
			WHERE (entitys.is_active = true) AND (entity_id = v_entity_id);

		END IF;

		IF(v_entity_id is null)THEN
			SELECT entity_id INTO v_entity_id
			FROM entitys
			WHERE (is_active = true) AND (svcb_son = rec.svcb_son);
			SELECT org_id INTO v_org_id
			FROM entitys
			WHERE (is_active = true) AND (entity_id = v_entity_id);
			IF(v_org_id is null)THEN v_entity_id := 0; v_org_id := 0; END IF;
		END IF;

		IF(v_entity_id is null)THEN v_entity_id := 0; v_org_id := 0; END IF;

		--- Compute rooot points
		IF(v_entity_id <> 0)THEN
			v_root_points := v_root_points + rec.totalsegs;
		END IF;

		SELECT points_id INTO v_points_id
		FROM points WHERE (period_id = v_period_id) AND (entity_id = v_entity_id)
			AND (pcc = rec.pcc) AND (son = rec.son);

		IF(v_points_id is null)THEN
			SELECT points_id INTO v_points_id
			FROM points WHERE (period_id = v_period_id) AND (entity_id = v_entity_id)
				AND (son = rec.son);
		END IF;

		IF(v_points_id is null)THEN
			INSERT INTO points (point_date, period_id, org_id, entity_id, pcc, son, segments, amount, points)
			VALUES (period, v_period_id, v_org_id, v_entity_id, rec.pcc, rec.son, rec.totalsegs, v_amount, v_points);
		ELSE
			UPDATE points SET segments = rec.totalsegs, amount = v_amount, points = v_points
			WHERE points_id = v_points_id;
		END IF;
	END LOOP;

	IF(v_start_date >= '2016-06-01'::date)THEN
		SELECT points_id INTO v_points_id
		FROM points WHERE (period_id = v_period_id) AND (entity_id = 0) AND (pcc is null) AND (son is null);

		IF(v_points_id is null )THEN
			INSERT INTO points (point_date, period_id, org_id, entity_id, amount, points)
			VALUES (period, v_period_id, 0, 0, 2, v_root_points * 2);
		ELSE
			UPDATE points SET amount = 2, points = v_root_points * 2
			WHERE points_id = v_points_id;
		END IF;
	END IF;

	IF(rec IS NULL)THEN
		RAISE EXCEPTION 'There are no segments for this month';
	ELSE
		msg := 'Points computed';
	END IF;
	RETURN msg;
END;
$$ LANGUAGE plpgsql;
