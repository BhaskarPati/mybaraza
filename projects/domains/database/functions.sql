CREATE OR REPLACE FUNCTION ins_domains_aft() RETURNS trigger AS $$
BEGIN
	INSERT INTO domain_hosts (domain_id, host_id, updated)
	SELECT NEW.domain_id, host_id, true
	FROM hosts
	WHERE (core_host = true) AND (updated = true);
	RETURN NULL;
END;
$$
  LANGUAGE plpgsql ;

CREATE TRIGGER ins_domains_aft AFTER INSERT ON domains
FOR EACH ROW EXECUTE PROCEDURE ins_domains_aft();

CREATE OR REPLACE FUNCTION ins_domains() RETURNS trigger AS $$
BEGIN
    NEW.auth_info := substring(md5(CAST(random() as text)) from 3 for 12);
    NEW.expiry_date	:= now() + CAST(CAST(NEW.duration as text ) || ' years' as interval);
    RETURN NEW;
END;
$$
LANGUAGE plpgsql;

CREATE TRIGGER ins_domains BEFORE INSERT ON domains
FOR EACH ROW
EXECUTE PROCEDURE ins_domains();
