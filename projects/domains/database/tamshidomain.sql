---Project Database File


CREATE VIEW vw_address AS
	SELECT address_types.address_type_id, address_types.address_type_name, orgs.org_id, orgs.org_name, sys_countrys.sys_country_id, sys_countrys.sys_country_name, address.address_id, address.address_name, address.table_name, address.table_id, address.post_office_box, address.postal_code, address.premises, address.street, address.town, address.phone_number, address.extension, address.mobile, address.fax, address.email, address.website, address.is_default, address.first_password, address.details, address.google_token
	FROM address
	INNER JOIN address_types ON address.address_type_id = address_types.address_type_id
	INNER JOIN orgs ON address.org_id = orgs.org_id
	INNER JOIN sys_countrys ON address.sys_country_id = sys_countrys.sys_country_id;

CREATE VIEW vw_address_types AS
	SELECT orgs.org_id, orgs.org_name, address_types.address_type_id, address_types.address_type_name
	FROM address_types
	INNER JOIN orgs ON address_types.org_id = orgs.org_id;

CREATE VIEW vw_domain_host_packages AS
	SELECT domain_host_packages.package_id, domain_host_packages.package_name, domain_host_packages.annual_fee, domain_host_packages.disk_space, domain_host_packages.dns_management, domain_host_packages.no_of_emails, domain_host_packages.total_email_storage, domain_host_packages.webmail, domain_host_packages.email_aliases, domain_host_packages.imap_pop3_smtps, domain_host_packages.cache_all_email_address, domain_host_packages.virus_email_protection, domain_host_packages.auto_responder, domain_host_packages.mysql_postgres, domain_host_packages.backup_recovery, domain_host_packages.web_admin_tool, domain_host_packages.ftp_accounts, domain_host_packages.web_statistics, domain_host_packages.file_manager, domain_host_packages.web_development, domain_host_packages.php5, domain_host_packages.phyton, domain_host_packages.perl_ogi
	FROM domain_host_packages;

CREATE VIEW vw_domain_hosts AS
	SELECT domains.domain_id, domains.domain_name, hosts.host_id, hosts.host_name, domain_hosts.domain_host_id, domain_hosts.updated
	FROM domain_hosts
	INNER JOIN domains ON domain_hosts.domain_id = domains.domain_id
	INNER JOIN hosts ON domain_hosts.host_id = hosts.host_id;

CREATE VIEW vw_domains AS
	SELECT entitys.entity_id, entitys.entity_name, zones.zone_id, zones.zone_name, domains.domain_id, domains.domain_name, domains.site_name, domains.site_user, domains.google_token, domains.auth_info, domains.created_date, domains.transfer_date, domains.duration, domains.expiry_date, domains.updated, domains.google_sync, domains.details
	FROM domains
	INNER JOIN entitys ON domains.entity_id = entitys.entity_id
	INNER JOIN zones ON domains.zone_id = zones.zone_id;

CREATE VIEW vw_entity_subscriptions AS
	SELECT entity_types.entity_type_id, entity_types.entity_type_name, entitys.entity_id, entitys.entity_name, orgs.org_id, orgs.org_name, subscription_levels.subscription_level_id, subscription_levels.subscription_level_name, entity_subscriptions.entity_subscription_id, entity_subscriptions.details
	FROM entity_subscriptions
	INNER JOIN entity_types ON entity_subscriptions.entity_type_id = entity_types.entity_type_id
	INNER JOIN entitys ON entity_subscriptions.entity_id = entitys.entity_id
	INNER JOIN orgs ON entity_subscriptions.org_id = orgs.org_id
	INNER JOIN subscription_levels ON entity_subscriptions.subscription_level_id = subscription_levels.subscription_level_id;

CREATE VIEW vw_entity_types AS
	SELECT orgs.org_id, orgs.org_name, entity_types.entity_type_id, entity_types.entity_type_name, entity_types.entity_role, entity_types.use_key, entity_types.start_view, entity_types.group_email, entity_types.description, entity_types.details
	FROM entity_types
	INNER JOIN orgs ON entity_types.org_id = orgs.org_id;

CREATE VIEW vw_entitys AS
	SELECT entity_types.entity_type_id, entity_types.entity_type_name, orgs.org_id, orgs.org_name, entitys.entity_id, entitys.entity_name, entitys.user_name, entitys.primary_email, entitys.primary_telephone, entitys.super_user, entitys.entity_leader, entitys.no_org, entitys.function_role, entitys.date_enroled, entitys.is_active, entitys.entity_password, entitys.first_password, entitys.new_password, entitys.start_url, entitys.is_picked, entitys.details, entitys.son, entitys.phone_ph, entitys.phone_pa, entitys.phone_pb, entitys.phone_pt, entitys.contact_key, entitys.auth_info, entitys.progress_status, entitys.progress_details, entitys.updated
	FROM entitys
	INNER JOIN entity_types ON entitys.entity_type_id = entity_types.entity_type_id
	INNER JOIN orgs ON entitys.org_id = orgs.org_id;

CREATE VIEW vw_hosting AS
	SELECT hosting.hosting_id, hosting.hosting_name, hosting.hosting_price, hosting.details
	FROM hosting;

CREATE VIEW vw_hosts AS
	SELECT hosts.host_id, hosts.host_name, hosts.core_host, hosts.updated, hosts.details
	FROM hosts;

CREATE VIEW vw_ledger AS
	SELECT domains.domain_id, domains.domain_name, entitys.entity_id, entitys.entity_name, mpesa_trxs.mpesa_trx_id, mpesa_trxs.mpesa_trx_name, ledger.ledger_id, ledger.trans_type, ledger.payment_date, ledger.ledger_date, ledger.trx_code, ledger.amount, ledger.tax_amount, ledger.cheque, ledger.cleared, ledger.details
	FROM ledger
	INNER JOIN domains ON ledger.domain_id = domains.domain_id
	INNER JOIN entitys ON ledger.entity_id = entitys.entity_id
	INNER JOIN mpesa_trxs ON ledger.mpesa_trx_id = mpesa_trxs.mpesa_trx_id;

CREATE VIEW vw_mpesa_trxs AS
	SELECT orgs.org_id, orgs.org_name, mpesa_trxs.mpesa_trx_id, mpesa_trxs.mpesa_id, mpesa_trxs.mpesa_orig, mpesa_trxs.mpesa_dest, mpesa_trxs.mpesa_tstamp, mpesa_trxs.mpesa_text, mpesa_trxs.mpesa_code, mpesa_trxs.mpesa_acc, mpesa_trxs.mpesa_msisdn, mpesa_trxs.mpesa_trx_date, mpesa_trxs.mpesa_trx_time, mpesa_trxs.mpesa_amt, mpesa_trxs.mpesa_sender, mpesa_trxs.mpesa_pick_time
	FROM mpesa_trxs
	INNER JOIN orgs ON mpesa_trxs.org_id = orgs.org_id;

CREATE VIEW vw_orgs AS
	SELECT orgs.org_id, orgs.currency_id, orgs.parent_org_id, orgs.org_name, orgs.org_sufix, orgs.is_default, orgs.is_active, orgs.logo, orgs.pin, orgs.details, orgs.pcc, orgs.sp_id, orgs.service_id, orgs.sender_name, orgs.sms_rate, orgs.show_fare, orgs.gds_free_field, orgs.credit_limit
	FROM orgs;

CREATE VIEW vw_package_host AS
	SELECT domain_host_packages.package_id, domain_host_packages.package_name, domains.domain_id, domains.domain_name, package_host.package_host_id, package_host.updated
	FROM package_host
	INNER JOIN domain_host_packages ON package_host.package_id = domain_host_packages.package_id
	INNER JOIN domains ON package_host.domain_id = domains.domain_id;

CREATE VIEW vw_sites AS
	SELECT hosting.hosting_id, hosting.hosting_name, sites.site_id, sites.site_name, sites.site_price, sites.details
	FROM sites
	INNER JOIN hosting ON sites.hosting_id = hosting.hosting_id;

CREATE VIEW vw_sms_trans AS
	SELECT orgs.org_id, orgs.org_name, sms_trans.sms_trans_id, sms_trans.message, sms_trans.origin, sms_trans.sms_time, sms_trans.client_id, sms_trans.msg_number, sms_trans.code, sms_trans.amount, sms_trans.in_words, sms_trans.narrative, sms_trans.sms_id, sms_trans.sms_deleted, sms_trans.sms_picked, sms_trans.part_id, sms_trans.part_message, sms_trans.part_no, sms_trans.part_count, sms_trans.complete
	FROM sms_trans
	INNER JOIN orgs ON sms_trans.org_id = orgs.org_id;

CREATE VIEW vw_subscription_levels AS
	SELECT orgs.org_id, orgs.org_name, subscription_levels.subscription_level_id, subscription_levels.subscription_level_name, subscription_levels.details
	FROM subscription_levels
	INNER JOIN orgs ON subscription_levels.org_id = orgs.org_id;

CREATE VIEW vw_sys_continents AS
	SELECT sys_continents.sys_continent_id, sys_continents.sys_continent_name
	FROM sys_continents;

CREATE VIEW vw_sys_countrys AS
	SELECT sys_continents.sys_continent_id, sys_continents.sys_continent_name, sys_countrys.sys_country_id, sys_countrys.sys_country_code, sys_countrys.sys_country_number, sys_countrys.sys_phone_code, sys_countrys.sys_country_name, sys_countrys.sys_currency_name, sys_countrys.sys_currency_cents, sys_countrys.sys_currency_code, sys_countrys.sys_currency_exchange
	FROM sys_countrys
	INNER JOIN sys_continents ON sys_countrys.sys_continent_id = sys_continents.sys_continent_id;

CREATE VIEW vw_sys_emailed AS
	SELECT orgs.org_id, orgs.org_name, sys_emails.sys_email_id, sys_emails.sys_email_name, sys_emailed.sys_emailed_id, sys_emailed.table_id, sys_emailed.table_name, sys_emailed.email_type, sys_emailed.emailed, sys_emailed.narrative
	FROM sys_emailed
	INNER JOIN orgs ON sys_emailed.org_id = orgs.org_id
	INNER JOIN sys_emails ON sys_emailed.sys_email_id = sys_emails.sys_email_id;

CREATE VIEW vw_sys_emails AS
	SELECT orgs.org_id, orgs.org_name, sys_emails.sys_email_id, sys_emails.sys_email_name, sys_emails.default_email, sys_emails.title, sys_emails.details
	FROM sys_emails
	INNER JOIN orgs ON sys_emails.org_id = orgs.org_id;

CREATE VIEW vw_sys_logins AS
	SELECT entitys.entity_id, entitys.entity_name, sys_logins.sys_login_id, sys_logins.login_time, sys_logins.login_ip, sys_logins.narrative
	FROM sys_logins
	INNER JOIN entitys ON sys_logins.entity_id = entitys.entity_id;

CREATE VIEW vw_zones AS
	SELECT zones.zone_id, zones.zone_name, zones.zone_key, zones.annual_cost, zones.tax_rate, zones.details
	FROM zones;


CREATE VIEW vw_address AS
	SELECT address_types.address_type_id, address_types.address_type_name, orgs.org_id, orgs.org_name, sys_countrys.sys_country_id, sys_countrys.sys_country_name, address.address_id, address.address_name, address.table_name, address.table_id, address.post_office_box, address.postal_code, address.premises, address.street, address.town, address.phone_number, address.extension, address.mobile, address.fax, address.email, address.website, address.is_default, address.first_password, address.details, address.google_token
	FROM address
	INNER JOIN address_types ON address.address_type_id = address_types.address_type_id
	INNER JOIN orgs ON address.org_id = orgs.org_id
	INNER JOIN sys_countrys ON address.sys_country_id = sys_countrys.sys_country_id;

CREATE VIEW vw_address_types AS
	SELECT orgs.org_id, orgs.org_name, address_types.address_type_id, address_types.address_type_name
	FROM address_types
	INNER JOIN orgs ON address_types.org_id = orgs.org_id;

CREATE VIEW vw_domain_host_packages AS
	SELECT domain_host_packages.package_id, domain_host_packages.package_name, domain_host_packages.annual_fee, domain_host_packages.disk_space, domain_host_packages.dns_management, domain_host_packages.no_of_emails, domain_host_packages.total_email_storage, domain_host_packages.webmail, domain_host_packages.email_aliases, domain_host_packages.imap_pop3_smtps, domain_host_packages.cache_all_email_address, domain_host_packages.virus_email_protection, domain_host_packages.auto_responder, domain_host_packages.mysql_postgres, domain_host_packages.backup_recovery, domain_host_packages.web_admin_tool, domain_host_packages.ftp_accounts, domain_host_packages.web_statistics, domain_host_packages.file_manager, domain_host_packages.web_development, domain_host_packages.php5, domain_host_packages.phyton, domain_host_packages.perl_ogi
	FROM domain_host_packages;

CREATE VIEW vw_domain_hosts AS
	SELECT domains.domain_id, domains.domain_name, hosts.host_id, hosts.host_name, domain_hosts.domain_host_id, domain_hosts.updated
	FROM domain_hosts
	INNER JOIN domains ON domain_hosts.domain_id = domains.domain_id
	INNER JOIN hosts ON domain_hosts.host_id = hosts.host_id;

CREATE VIEW vw_domains AS
	SELECT entitys.entity_id, entitys.entity_name, zones.zone_id, zones.zone_name, domains.domain_id, domains.domain_name, domains.site_name, domains.site_user, domains.google_token, domains.auth_info, domains.created_date, domains.transfer_date, domains.duration, domains.expiry_date, domains.updated, domains.google_sync, domains.details
	FROM domains
	INNER JOIN entitys ON domains.entity_id = entitys.entity_id
	INNER JOIN zones ON domains.zone_id = zones.zone_id;

CREATE VIEW vw_entity_subscriptions AS
	SELECT entity_types.entity_type_id, entity_types.entity_type_name, entitys.entity_id, entitys.entity_name, orgs.org_id, orgs.org_name, subscription_levels.subscription_level_id, subscription_levels.subscription_level_name, entity_subscriptions.entity_subscription_id, entity_subscriptions.details
	FROM entity_subscriptions
	INNER JOIN entity_types ON entity_subscriptions.entity_type_id = entity_types.entity_type_id
	INNER JOIN entitys ON entity_subscriptions.entity_id = entitys.entity_id
	INNER JOIN orgs ON entity_subscriptions.org_id = orgs.org_id
	INNER JOIN subscription_levels ON entity_subscriptions.subscription_level_id = subscription_levels.subscription_level_id;

CREATE VIEW vw_entity_types AS
	SELECT orgs.org_id, orgs.org_name, entity_types.entity_type_id, entity_types.entity_type_name, entity_types.entity_role, entity_types.use_key, entity_types.start_view, entity_types.group_email, entity_types.description, entity_types.details
	FROM entity_types
	INNER JOIN orgs ON entity_types.org_id = orgs.org_id;

CREATE VIEW vw_entitys AS
	SELECT entity_types.entity_type_id, entity_types.entity_type_name, orgs.org_id, orgs.org_name, entitys.entity_id, entitys.entity_name, entitys.user_name, entitys.primary_email, entitys.primary_telephone, entitys.super_user, entitys.entity_leader, entitys.no_org, entitys.function_role, entitys.date_enroled, entitys.is_active, entitys.entity_password, entitys.first_password, entitys.new_password, entitys.start_url, entitys.is_picked, entitys.details, entitys.son, entitys.phone_ph, entitys.phone_pa, entitys.phone_pb, entitys.phone_pt, entitys.contact_key, entitys.auth_info, entitys.progress_status, entitys.progress_details, entitys.updated
	FROM entitys
	INNER JOIN entity_types ON entitys.entity_type_id = entity_types.entity_type_id
	INNER JOIN orgs ON entitys.org_id = orgs.org_id;

CREATE VIEW vw_hosting AS
	SELECT hosting.hosting_id, hosting.hosting_name, hosting.hosting_price, hosting.details
	FROM hosting;

CREATE VIEW vw_hosts AS
	SELECT hosts.host_id, hosts.host_name, hosts.core_host, hosts.updated, hosts.details
	FROM hosts;

CREATE VIEW vw_ledger AS
	SELECT domains.domain_id, domains.domain_name, entitys.entity_id, entitys.entity_name, mpesa_trxs.mpesa_trx_id, mpesa_trxs.mpesa_trx_name, ledger.ledger_id, ledger.trans_type, ledger.payment_date, ledger.ledger_date, ledger.trx_code, ledger.amount, ledger.tax_amount, ledger.cheque, ledger.cleared, ledger.details
	FROM ledger
	INNER JOIN domains ON ledger.domain_id = domains.domain_id
	INNER JOIN entitys ON ledger.entity_id = entitys.entity_id
	INNER JOIN mpesa_trxs ON ledger.mpesa_trx_id = mpesa_trxs.mpesa_trx_id;

CREATE VIEW vw_mpesa_trxs AS
	SELECT orgs.org_id, orgs.org_name, mpesa_trxs.mpesa_trx_id, mpesa_trxs.mpesa_id, mpesa_trxs.mpesa_orig, mpesa_trxs.mpesa_dest, mpesa_trxs.mpesa_tstamp, mpesa_trxs.mpesa_text, mpesa_trxs.mpesa_code, mpesa_trxs.mpesa_acc, mpesa_trxs.mpesa_msisdn, mpesa_trxs.mpesa_trx_date, mpesa_trxs.mpesa_trx_time, mpesa_trxs.mpesa_amt, mpesa_trxs.mpesa_sender, mpesa_trxs.mpesa_pick_time
	FROM mpesa_trxs
	INNER JOIN orgs ON mpesa_trxs.org_id = orgs.org_id;

CREATE VIEW vw_orgs AS
	SELECT orgs.org_id, orgs.currency_id, orgs.parent_org_id, orgs.org_name, orgs.org_sufix, orgs.is_default, orgs.is_active, orgs.logo, orgs.pin, orgs.details, orgs.pcc, orgs.sp_id, orgs.service_id, orgs.sender_name, orgs.sms_rate, orgs.show_fare, orgs.gds_free_field, orgs.credit_limit
	FROM orgs;

CREATE VIEW vw_package_host AS
	SELECT domain_host_packages.package_id, domain_host_packages.package_name, domains.domain_id, domains.domain_name, package_host.package_host_id, package_host.updated
	FROM package_host
	INNER JOIN domain_host_packages ON package_host.package_id = domain_host_packages.package_id
	INNER JOIN domains ON package_host.domain_id = domains.domain_id;

CREATE VIEW vw_sites AS
	SELECT hosting.hosting_id, hosting.hosting_name, sites.site_id, sites.site_name, sites.site_price, sites.details
	FROM sites
	INNER JOIN hosting ON sites.hosting_id = hosting.hosting_id;

CREATE VIEW vw_sms_trans AS
	SELECT orgs.org_id, orgs.org_name, sms_trans.sms_trans_id, sms_trans.message, sms_trans.origin, sms_trans.sms_time, sms_trans.client_id, sms_trans.msg_number, sms_trans.code, sms_trans.amount, sms_trans.in_words, sms_trans.narrative, sms_trans.sms_id, sms_trans.sms_deleted, sms_trans.sms_picked, sms_trans.part_id, sms_trans.part_message, sms_trans.part_no, sms_trans.part_count, sms_trans.complete
	FROM sms_trans
	INNER JOIN orgs ON sms_trans.org_id = orgs.org_id;

CREATE VIEW vw_subscription_levels AS
	SELECT orgs.org_id, orgs.org_name, subscription_levels.subscription_level_id, subscription_levels.subscription_level_name, subscription_levels.details
	FROM subscription_levels
	INNER JOIN orgs ON subscription_levels.org_id = orgs.org_id;

CREATE VIEW vw_sys_continents AS
	SELECT sys_continents.sys_continent_id, sys_continents.sys_continent_name
	FROM sys_continents;

CREATE VIEW vw_sys_countrys AS
	SELECT sys_continents.sys_continent_id, sys_continents.sys_continent_name, sys_countrys.sys_country_id, sys_countrys.sys_country_code, sys_countrys.sys_country_number, sys_countrys.sys_phone_code, sys_countrys.sys_country_name, sys_countrys.sys_currency_name, sys_countrys.sys_currency_cents, sys_countrys.sys_currency_code, sys_countrys.sys_currency_exchange
	FROM sys_countrys
	INNER JOIN sys_continents ON sys_countrys.sys_continent_id = sys_continents.sys_continent_id;

CREATE VIEW vw_sys_emailed AS
	SELECT orgs.org_id, orgs.org_name, sys_emails.sys_email_id, sys_emails.sys_email_name, sys_emailed.sys_emailed_id, sys_emailed.table_id, sys_emailed.table_name, sys_emailed.email_type, sys_emailed.emailed, sys_emailed.narrative
	FROM sys_emailed
	INNER JOIN orgs ON sys_emailed.org_id = orgs.org_id
	INNER JOIN sys_emails ON sys_emailed.sys_email_id = sys_emails.sys_email_id;

CREATE VIEW vw_sys_emails AS
	SELECT orgs.org_id, orgs.org_name, sys_emails.sys_email_id, sys_emails.sys_email_name, sys_emails.default_email, sys_emails.title, sys_emails.details
	FROM sys_emails
	INNER JOIN orgs ON sys_emails.org_id = orgs.org_id;

CREATE VIEW vw_sys_logins AS
	SELECT entitys.entity_id, entitys.entity_name, sys_logins.sys_login_id, sys_logins.login_time, sys_logins.login_ip, sys_logins.narrative
	FROM sys_logins
	INNER JOIN entitys ON sys_logins.entity_id = entitys.entity_id;

CREATE VIEW vw_zones AS
	SELECT zones.zone_id, zones.zone_name, zones.zone_key, zones.annual_cost, zones.tax_rate, zones.details
	FROM zones;


