SELECT pg_catalog.setval('webshow_webshowid_seq', 22, true);


INSERT INTO webshow (webshowid, showgroup, narrative, details) VALUES (1, 1, 'Application Submision', 'Dear Applicant,<br><br>
Your application to become .ke registrar for {{applicantname}} has been submitted to KeNIC for processing and approval.<br><br>
Please forward and application letter and accompanied by your Company''s Profile detailing your company''s operations, location and abilities.<br><br>
In particular, the company profile should include:<br>
 1. your experience in DNS and DNS server management<br>
 2. at least two(2) DNS servers that your company manages and<br>
 3. a list of domain names hosted on the nameservers and details<br>
The KENIC management will evaluate your application within 48 Hours and respond with an approval or Rejection.<br><br>
If approved, you will have to complete the Registrar Accreditation Agreement (in duplicate) and pay the annual membership fees of Kshs. 5,000.00. It is estimated that the process should take 7 working days.<br><br>
Kindly note that the .KE Registry is still closed and thus to become an Accredited Registrar, your organisation must have local presence, that is, your organisation must have an office within the country (Kenya).<br><br>
Please feel free to contact us for any queries.<br><br>
Best Regards,<br>
Registry Services,<br>
registry@kenic.or.ke,<br>
http://www.kenic.or.ke,<br>
Kenya Network Information Centre (KeNIC)');
INSERT INTO webshow (webshowid, showgroup, narrative, details) VALUES (6, 2, 'New Domain registration', 'Dear Registrant,<br><br>
Your domain {{name}} has been registered in Kenic database.<br>
Verify carefully the ticket and the pendency information, in particular the instructions and expiration dates.<br><br>
Ticket: {{roid}}<br>
Domain: {{name}}<br>
Adm Id: {{clid}}<br>
Creation Date: {{createdate}}<br>
Expiry Date:   {{exdate}}<br><br>
Entity: <br>
  Owner ID: {{id}}<br>
  {{intpostalname}}<br>
  {{intpostalorg}}<br>
  {{intpostalstreet1}}<br>
  {{intpostalstreet2}}<br>
  {{intpostalstreet3}}<br>
  {{intpostalcity}}<br>
  {{intpostalsp}}<br>
  {{intpostalpc}}<br>
  {{intpostalcc}}<br>
  {{voice}}<br><br>
Your domain will be working on the next DNS publication. <br>
In case of doubts, please feel free to contact your Registar.<br><br>
{{clientname}} on {{admin_email}} or {{registar_phone}}.<br><br>
Best Regards,<br>
Kenya Network Information Centre (KeNIC)');
INSERT INTO webshow (webshowid, showgroup, narrative, details) VALUES (2, 1, 'Application Approval', 'Dear Applicant,<br><br>
Your application at KeNIC to be .ke registrar has been approved.<br>
Your user-id is {{clid}} and your password is {{firstpasswd}}.<br>
Please get intouch with the technical department for information and training on use of the Registry System.<br>
Your account has been Debited with KES 5,000 being Annual Membership fee.<br>
Proceed to http://ns0.kenic.or.ke to begin registration.<br><br>
Best Regards,<br>
Registry Services,<br>
registry@kenic.or.ke,<br>
http://www.kenic.or.ke,<br>
Kenya Network Information Centre (KeNIC)');
INSERT INTO webshow (webshowid, showgroup, narrative, details) VALUES (3, 1, 'Processing Application', 'Dear Applicant,<br><br>
Your application at KeNIC to be .ke registrar is pending approval due to the following reasons:<br><br>
{{details}}<br><br>
Best Regards,<br>
Registry Services,<br>
registry@kenic.or.ke,<br>
http://www.kenic.or.ke,<br>
Kenya Network Information Centre (KeNIC)');
INSERT INTO webshow (webshowid, showgroup, narrative, details) VALUES (4, 1, 'Application Rejection', 'Dear Applicant,<br><br>
Your application at KeNIC to be .ke registrar has been rejected due to the following reasons:<br><br>
{{details}}<br><br>
Best Regards,<br>
Registry Services,<br>
registry@kenic.or.ke,<br>
http://www.kenic.or.ke,<br>
Kenya Network Information Centre (KeNIC)');
INSERT INTO webshow (webshowid, showgroup, narrative, details) VALUES (8, 2, 'Goverment Domain Registration', 'Dear Registar,<br><br>
Your domain has been registered but it is not active pending submision of relevant documentation.<br><br>
For your request to be accepted and the domain name registered KeNIC Requires a Certificate from the Goverment.<br><br>
Ticket: {{roid}}<br>
Domain: {{name}}<br>
Adm Id: {{clid}}<br>
Creation Date:  {{createdate}}<br>
Expiry Date:    {{exdate}}<br><br>
Entity: <br>
  Owner ID: {{id}}<br>
  {{intpostalname}}<br>
  {{intpostalorg}}<br>
  {{intpostalstreet1}}<br>
  {{intpostalstreet2}}<br>
  {{intpostalstreet3}}<br>
  {{intpostalcity}}<br>
  {{intpostalsp}}<br>
  {{intpostalpc}}<br>
  {{intpostalcc}}<br>
  {{voice}}<br><br>
The address to send documentations to KeNIC is:<br>
Kenya Network Information Centre (KeNIC)<br>
Waiyaki Way, Opp. Kianda School<br>
P.O Box 1461 -00606 - Nairobi,<br>
Kenya<br><br>
OR Fax the documents to:<br>
KENIC Registry Services<br>
Fax: +254204450087<br><br>
In case of doubts, please feel free to contact us on Registry@kenic.or.ke.<br><br>
Best Regards,<br>
Registry Services,<br>
billing@kenic.or.ke,<br>
http://www.kenic.or.ke,<br>
Kenya Network Information Centre (KeNIC)');
INSERT INTO webshow (webshowid, showgroup, narrative, details) VALUES (5, 2, 'New Domain registration', 'Dear Registar,<br><br>
Your request for domain registration; {{name}} was accepted and registered in Kenic database.<br>
Verify carefully the ticket and the pendency information, in particular the instructions and expiration dates.<br><br>
Ticket: {{roid}}<br>
Domain: {{name}}<br>
Adm Id: {{clid}}<br>
Creation Date: {{createdate}}<br>
Expiry Date:   {{exdate}}<br><br>
Entity: <br>
  Owner ID: {{id}}<br>
  {{intpostalname}}<br>
  {{intpostalorg}}<br>
  {{intpostalstreet1}}<br>
  {{intpostalstreet2}}<br>
  {{intpostalstreet3}}<br>
  {{intpostalcity}}<br>
  {{intpostalsp}}<br>
  {{intpostalpc}}<br>
  {{intpostalcc}}<br>
  {{voice}}<br><br>
Your domain will be working on the next DNS publication. <br>
In case of doubts, please feel free to contact us.<br><br>
Best Regards,<br>
Registry Services,<br>
registry@kenic.or.ke,<br>
http://www.kenic.or.ke,<br>
Kenya Network Information Centre (KeNIC)');
INSERT INTO webshow (webshowid, showgroup, narrative, details) VALUES (21, 7, 'Domain Deletion', 'Dear Registrar,<br><br>
The domain {{domainname}} has been deleted and a credit note issued for this domain.
The domain will be removed from the system on the next publishing cycle.
Best Regards,<br>
Registry Services,<br>
registry@kenic.or.ke,<br>
http://www.kenic.or.ke,<br>
Kenya Network Information Centre (KeNIC)
');
INSERT INTO webshow (webshowid, showgroup, narrative, details) VALUES (22, 7, 'Domain Deletion', 'Dear Registrar,<br><br>
The domain {{domainname}} has been deleted and will be removed from the system on the next publishing cycle.
Best Regards,<br>
Registry Services,<br>
registry@kenic.or.ke,<br>
http://www.kenic.or.ke,<br>
Kenya Network Information Centre (KeNIC)');
INSERT INTO webshow (webshowid, showgroup, narrative, details) VALUES (7, 2, 'Academic Domain Registration', 'Dear Registar,<br><br>
Your domain has been registered but it is not active pending submision of relevant documentation.<br><br>
For your request to be accepted and the domain name registered KeNIC Requires a Certificate from Ministry of Education.<br><br>
Ticket: {{roid}}<br>
Domain: {{name}}<br>
Adm Id: {{clid}}<br>
Creation Date: {{createdate}}<br>
Expiry Date:   {{exdate}}<br><br>
Entity: <br>
  Owner ID: {{id}}<br>
  {{intpostalname}}<br>
  {{intpostalorg}}<br>
  {{intpostalstreet1}}<br>
  {{intpostalstreet2}}<br>
  {{intpostalstreet3}}<br>
  {{intpostalcity}}<br>
  {{intpostalsp}}<br>
  {{intpostalpc}}<br>
  {{intpostalcc}}<br>
  {{voice}}<br><br>
The address to send documentations to KeNIC is:<br>
Kenya Network Information Centre (KeNIC)<br>
Waiyaki Way, Opp. Kianda School<br>
P.O Box 1461 -00606 - Nairobi,<br>
Kenya<br><br>
OR Fax the documents to:<br>
KENIC Registry Services<br>
Fax: +254204450087<br><br>
In case of doubts, please feel free to contact us on Registry@kenic.or.ke.<br><br>
Best Regards,<br>
Registry Services,<br>
billing@kenic.or.ke,<br>
http://www.kenic.or.ke,<br>
Kenya Network Information Centre (KeNIC)');
INSERT INTO webshow (webshowid, showgroup, narrative, details) VALUES (9, 3, 'Domain Renewal', 'Dear Registar,<br><br>
Your request to renew the domain {{name}} was accepted.<br>
Verify carefully the ticket and the pendency information, in particular the instructions and expiration dates.<br><br>
Ticket: {{roid}}<br>
Domain: {{name}}<br>
Adm Id: {{clid}}<br>
Creation Date: {{createdate}}<br>
Renewal Date:  {{updatedate}}<br>
Expiry date:   {{exdate}}<br><br>
Entity: <br>
  Owner ID: {{id}}<br>
  {{intpostalname}}<br>
  {{intpostalorg}}<br>
  {{intpostalstreet1}}<br>
  {{intpostalstreet2}}<br>
  {{intpostalstreet3}}<br>
  {{intpostalcity}}<br>
  {{intpostalsp}}<br>
  {{intpostalpc}}<br>
  {{intpostalcc}}<br>
  {{voice}}<br><br>
Your domain will be working on the next DNS publication. <br>
In case of doubts, please feel free to contact us.<br><br>
Best Regards,<br>
Registry Services,<br>
billing@kenic.or.ke,<br>
http://www.kenic.or.ke,<br>
Kenya Network Information Centre (KeNIC)');
INSERT INTO webshow (webshowid, showgroup, narrative, details) VALUES (10, 3, 'Domain Renewal', 'Dear Registrant,<br><br>
Your domain {{name}} has been renewed.<br>
Verify carefully the ticket and the pendency information, in particular the instructions and expiration dates.<br><br>
Ticket: {{roid}}<br>
Domain: {{name}}<br>
Adm Id: {{clid}}<br>
Creation Date: {{createdate}}<br>
Renewal Date:  {{updatedate}}<br>
Expiry date:   {{exdate}}<br><br>
Entity: <br>
  Owner ID: {{id}}<br>
  {{intpostalname}}<br>
  {{intpostalorg}}<br>
  {{intpostalstreet1}}<br>
  {{intpostalstreet2}}<br>
  {{intpostalstreet3}}<br>
  {{intpostalcity}}<br>
  {{intpostalsp}}<br>
  {{intpostalpc}}<br>
  {{intpostalcc}}<br>
  {{voice}}<br><br>
Your domain will be working on the next DNS publication. <br>
In case of doubts, please feel free to contact your domain name Registar.<br><br>
{{clientname}} on {{admin_email}} or {{registar_phone}}.<br><br>
Best Regards,<br>
Kenya Network Information Centre (KeNIC)');
INSERT INTO webshow (webshowid, showgroup, narrative, details) VALUES (11, 4, 'Domain Renewal notice', 'Dear Registar,<br><br>
Your domain will be expiring in the next {{domainage}} days.<br>
For your convenience, kindly renewal your domain.<br><br>
Domain: {{domainname}}<br>
Registered on: {{registerdate}}<br>
Expiry on :  {{exdate}}<br><br>
Renewal from {{exdate}} to {{next_expdate}} <br>
KSh {{renew_price}} <br>
VAT Amount: KSh {{renew_vat}} <br><br>
Best Regards,<br>
Registry Services,<br>
billing@kenic.or.ke,<br>
http://www.kenic.or.ke,<br>
Kenya Network Information Centre (KeNIC)');
INSERT INTO webshow (webshowid, showgroup, narrative, details) VALUES (12, 4, 'Domain Renewal notice', 'Dear Registrant,<br><br>
Your domain will be expiring in the next {{domainage}} days.<br>
For your convenience, kindly renewal your domain.<br><br>
Domain: {{domainname}}<br>
Registered on: {{registerdate}}<br>
Expiry on :  {{exdate}}<br><br>
Please contract your domain Registar to get the domain name renewed.<br>
{{clientname}} on {{admin_email}} or {{registar_phone}}.<br><br>
Best Regards,<br>
Kenya Network Information Centre (KeNIC)');
INSERT INTO webshow (webshowid, showgroup, narrative, details) VALUES (13, 4, 'Domain Renewal notice', 'Dear Registar,<br><br>
Your domain will be expiring today.<br>
For your convenience, kindly renewal your domain.<br><br>
Domain: {{domainname}}<br>
Registered on: {{registerdate}}<br>
Expiry on :  {{exdate}}<br><br>
Renewal from {{exdate}} to {{next_expdate}} <br>
KSh {{renew_price}} <br>
VAT Amount: KSh {{renew_vat}} <br><br>
Best Regards,<br>
Registry Services,<br>
billing@kenic.or.ke,<br>
http://www.kenic.or.ke,<br>
Kenya Network Information Centre (KeNIC)');
INSERT INTO webshow (webshowid, showgroup, narrative, details) VALUES (14, 4, 'Domain Renewal Notice', 'Dear Registrant,<br><br>
Your domain will be expiring today.<br>
For your convenience, kindly renewal your domain.<br><br>
Domain: {{domainname}}<br>
Registered on: {{registerdate}}<br>
Expiry on :  {{exdate}}<br><br>
Please contract your domain Registar to get the domain name renewed.<br>
{{clientname}} on {{admin_email}} or {{registar_phone}}.<br><br>
Best Regards,<br>
Kenya Network Information Centre (KeNIC)');
INSERT INTO webshow (webshowid, showgroup, narrative, details) VALUES (16, 5, 'Domain Deletion Notification', 'Dear Registrant,<br><br>
Your domain {{domainname}} expired on {{exdate}} and will be deleted in the next {{domainage}} days.<br>
For your convenience, kindly renewal your domain.<br><br>
Domain: {{domainname}}<br>
Registered on: {{registerdate}}<br>
Expired On :  {{exdate}}<br>
Deletion Date :  {{deldate}}<br>
Please contract your domain Registar to get the domain name renewed.<br>
{{clientname}} on {{admin_email}} or {{registar_phone}}.<br><br>
Best Regards,<br>
Kenya Network Information Centre (KeNIC)');
INSERT INTO webshow (webshowid, showgroup, narrative, details) VALUES (15, 5, 'Domain Deletion Notification', 'Dear Registar,<br><br>
Your domain {{domainname}} expired on {{exdate}} and will be deleted in the next {{domainage}} days.<br>
For your convenience, kindly renewal your domain.<br><br>
Domain: {{domainname}}<br>
Registered on: {{registerdate}}<br>
Expired On :  {{exdate}}<br>
Deletion Date :  {{deldate}}<br>
Renewal from {{exdate}} to {{next_expdate}} <br>
KSh {{renew_price}} <br>
VAT Amount: KSh {{renew_vat}} <br><br>
Best Regards,<br>
Registry Services,<br>
billing@kenic.or.ke,<br>
http://www.kenic.or.ke,<br>
Kenya Network Information Centre (KeNIC)');
INSERT INTO webshow (webshowid, showgroup, narrative, details) VALUES (17, 6, 'Domain Transfer request', 'Dear Registrar,<br><br>
You have sent a request to {{owner}} to transfer the domain {{domainname}} to you.<br>
The request message has been sent to {{owner}} whose contact is {{owner_email}} and {{owner_phone}} to authorize for the transfer.<br>
Best Regards,<br>
Registry Services,<br>
registry@kenic.or.ke,<br>
http://www.kenic.or.ke,<br>
Kenya Network Information Centre (KeNIC)');
INSERT INTO webshow (webshowid, showgroup, narrative, details) VALUES (18, 6, 'Domain Transfer request', 'Dear Registrar,<br><br>
You have been requested by {{requester}} to transfer the domain {{domainname}} to them.<br>
Please login into the registry system to Accept or Reject the transfer request.<br><br>
The request message has been sent from {{requester}} whose contact is {{requester_email}} and {{requester_phone}}.
Best Regards,<br>
Registry Services,<br>
registry@kenic.or.ke,<br>
http://www.kenic.or.ke,<br>
Kenya Network Information Centre (KeNIC)');
INSERT INTO webshow (webshowid, showgroup, narrative, details) VALUES (19, 6, 'Domain Transfer accepted', 'Dear Registrar,<br><br>
The request to transfer {{domainname}} from {{owner}} to {{requester}} has been accepted.
Best Regards,<br>
Registry Services,<br>
registry@kenic.or.ke,<br>
http://www.kenic.or.ke,<br>
Kenya Network Information Centre (KeNIC)');
INSERT INTO webshow (webshowid, showgroup, narrative, details) VALUES (20, 6, 'Domain Transfer declined', 'Dear Registrar,<br><br>
The request to transfer {{domainname}} from {{owner}} to {{requester}} has been declined.
Best Regards,<br>
Registry Services,<br>
registry@kenic.or.ke,<br>
http://www.kenic.or.ke,<br>
Kenya Network Information Centre (KeNIC)');

