CREATE VIEW vwdomains AS
SELECT dominio.id_dominio, lcase(concat(dominio.dominio, '.', dominio.stld)) as domainname, lcase(dominio.stld) as sld, dominio.data_atualizacao, 
dominio.renewed_until, dominio_reg.adm_handle, dominio_reg.tec_handle, dominio_reg.cob_handle,
concat(dominio.id_dominio, '-Kenic') as kenicid,
entidade.id_entidade, entidade.id_documento
FROM (dominio INNER JOIN dominio_reg ON dominio.id_dominio = dominio_reg.id_dominio)
	INNER JOIN entidade ON dominio_reg.id_entidade = entidade.id_entidade;

CREATE VIEW vwhost AS
SELECT lcase(hosts.hostname) as hostname, vwdomains.domainname, (max(hosts.host_order) + 1) as hostorder, 
	max(vwdomains.adm_handle) as adm_handle, hosts.ip_addr
FROM hosts INNER JOIN vwdomains ON hosts.id_dominio = vwdomains.id_dominio
GROUP BY lcase(hosts.hostname), vwdomains.domainname;

CREATE VIEW vwcharges AS
	(SELECT (CASE WHEN valor1 = 200000 THEN concat('Invoice for ', vwdomains.domainname, ' registered for 1 year') 
		ELSE concat('Invoice for ', vwdomains.domainname, ' registered for ', round(pendencia_dominio_pag.valor1 / 200000), ' years')
		END) as description, 
		vwdomains.adm_handle, vwdomains.domainname, vwdomains.sld, vwdomains.kenicid, pendencia_dominio.tempo_criacao as transdate,
		pendencia_dominio_pag.id_pendencia, round(valor1 * (100 - discount1) * (100 + vat) / 1000000, 2) as amount, 
		pendencia_dominio_pag.vat, 'VAT' as tax_label, 'Registration' as trans_type
	FROM (vwdomains INNER JOIN pendencia_dominio ON vwdomains.id_dominio = pendencia_dominio.id_dominio)
		INNER JOIN pendencia_dominio_pag ON pendencia_dominio.id_pendencia = pendencia_dominio_pag.id_pendencia
	WHERE (pendencia_dominio.info = 1060))
	UNION
	(SELECT concat('Payment for ', vwdomains.domainname) as description, 
		vwdomains.adm_handle, vwdomains.domainname, vwdomains.sld, vwdomains.kenicid, pendencia_dominio_pag.data_ult_pagamento,
		(50000 + pendencia_dominio_pag.id_pendencia) as paymentid, 
		((-1) * round(total_pago / 100, 2)) as amount, 0, '' as tax_label,'Payment' as trans_type
	FROM (vwdomains INNER JOIN pendencia_dominio ON vwdomains.id_dominio = pendencia_dominio.id_dominio)
		INNER JOIN pendencia_dominio_pag ON pendencia_dominio.id_pendencia = pendencia_dominio_pag.id_pendencia
	WHERE (pendencia_dominio.info = 1060));

