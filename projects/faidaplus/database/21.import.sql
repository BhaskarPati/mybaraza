



UPDATE faidaplus.user SET create_date = '2000-01-01 00:00:00' WHERE create_date <= '2000-01-01 00:00:00';
UPDATE faidaplus.user SET last_login = '2000-01-01 00:00:00' WHERE last_login <= '2000-01-01 00:00:00';
UPDATE faidaplus.user SET sms_alert = '0' WHERE sms_alert = '' or sms_alert = ' ';
UPDATE faidaplus.user SET email_alert = '0' WHERE email_alert = '' or email_alert = ' ';
UPDATE faidaplus.user SET newsletter = '0' WHERE newsletter = '' or newsletter = ' ';

UPDATE faidaplus.staff SET rel_id_salutation = 1 WHERE rel_id_salutation = 0;
UPDATE faidaplus.consultant SET create_date = '2000-01-01 00:00:00' WHERE create_date <= '2000-01-01 00:00:00';
UPDATE faidaplus.consultant SET birthdate = '1900-01-01' WHERE birthdate <= '1900-01-01';
UPDATE faidaplus.consultant SET birthdate = '1975-01-01' WHERE birthdate = '1975-00-00';
UPDATE faidaplus.consultant SET rel_id_salutation = 1 WHERE rel_id_salutation = 0;

UPDATE faidaplus.agency SET date_added = '2000-01-01 00:00:00' WHERE date_added <= '2000-01-01 00:00:00';
UPDATE faidaplus.agency SET last_production = '2000-01-01' WHERE last_production <= '2000-01-01';
UPDATE faidaplus.agency SET rel_id_staff = 28 WHERE rel_id_staff = 0;
UPDATE faidaplus.agency SET rel_id_town = 41 WHERE rel_id_town = 0;

UPDATE faidaplus.supplier SET create_date = '2000-01-01 00:00:00' WHERE create_date <= '2000-01-01 00:00:00';
UPDATE faidaplus.shop_item SET active = '0' WHERE active = '' or active = ' ';


UPDATE faidaplus.segment SET date = '2000-01-01' WHERE date <= '2000-01-01';
UPDATE faidaplus.segment SET date_time = '2000-01-01 00:00:00' WHERE date_time <= '2000-01-01 00:00:00';

