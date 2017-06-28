ALTER TABLE product_category ADD COLUMN icon character varying(50);
UPDATE product_category SET icon = 'fa-credit-card' WHERE product_category_id = 1;
UPDATE product_category SET icon = 'fa-cutlery' WHERE product_category_id = 2;
UPDATE product_category SET icon = 'fa-tv' WHERE product_category_id = 3;
UPDATE product_category SET icon = 'fa-car' WHERE product_category_id = 4;
UPDATE product_category SET icon = 'fa-paint-brush' WHERE product_category_id = 5;
UPDATE product_category SET icon = 'fa-cart-plus' WHERE product_category_id = 6;
UPDATE product_category SET icon = 'fa-shopping-cart' WHERE product_category_id = 8;
UPDATE product_category SET icon = 'fa-film' WHERE product_category_id = 9;
UPDATE product_category SET icon = 'fa-gift' WHERE product_category_id = 11;


CREATE OR REPLACE FUNCTION ins_periods() RETURNS trigger AS $$
DECLARE
	year_close 		BOOLEAN;
BEGIN
	SELECT year_closed INTO year_close
	FROM fiscal_years
	WHERE (fiscal_year_id = NEW.fiscal_year_id);

	IF (NEW.approve_status = 'Approved') THEN
		NEW.opened = false;
		NEW.activated = false;
	END IF;

	IF(year_close = true)THEN
		RAISE EXCEPTION 'The year is closed not transactions are allowed.';
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
