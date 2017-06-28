drop function getCreditLimit(integer);
CREATE FUNCTION getCreditLimit(integer) RETURNS double precision AS $$
	DECLARE
		credit_limit 	double precision;
		cover_amount 	double precision;
		paid_amount 	double precision;
		current_limit 	double precision;
		BEGIN
			credit_limit := COALESCE((SELECT orgs.credit_limit FROM orgs WHERE orgs.org_id = $1 GROUP BY orgs.credit_limit),0);
			cover_amount:= COALESCE((SELECT SUM(vw_allpassengers.totalamount_covered)AS cover_amount FROM vw_allpassengers WHERE org_id = $1
				GROUP BY org_id),0);

			paid_amount :=COALESCE((SELECT SUM(payment_amount)as payment_amount FROM payments WHERE org_id = $1 GROUP BY org_id),0);

			current_limit := (credit_limit + paid_amount) - cover_amount;


		RETURN current_limit;
		END;
$$LANGUAGE plpgsql;


CREATE FUNCTION getCreditLimitBalance(integer) RETURNS double precision AS $$
	DECLARE
		credit_limit 	double precision;
		cover_amount 	double precision;
		paid_amount 	double precision;
		current_limit_bl 	double precision;
		BEGIN
			credit_limit := COALESCE((SELECT orgs.credit_limit FROM orgs WHERE orgs.org_id = $1 GROUP BY orgs.credit_limit),0);
			cover_amount:= COALESCE((SELECT SUM(vw_allpassengers.totalamount_covered)AS cover_amount FROM vw_allpassengers WHERE org_id = $1
				GROUP BY org_id),0);

			current_limit_bl := ROUND(((credit_limit) - cover_amount)::numeric, 2);


		RETURN current_limit_bl;
		END;
$$LANGUAGE plpgsql;

CREATE FUNCTION getTotalAmount(integer) RETURNS double precision AS $$
	DECLARE
		cover_amount 	double precision;
		BEGIN
			cover_amount:= COALESCE((SELECT SUM(vw_allpassengers.totalamount_covered)AS cover_amount FROM vw_allpassengers WHERE org_id = $1
				GROUP BY org_id),0);

		RETURN ROUND(cover_amount::numeric,2);
		END;
$$LANGUAGE plpgsql;
