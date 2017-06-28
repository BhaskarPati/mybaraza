INSERT INTO sys_emails (sys_email_id, sys_email_name, title, details) VALUES (1, 'domain purchase', 'Thanks for purchasing {{domainname}}', '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<title>New Domain Registration</title>
</head>

<body>
<img src="http://tamshi.co.ke/forxml/newregistration.png" width="359" height="54" alt="tamshi" /><br />
<p><font face="Trebuchet MS, Arial, Helvetica, sans-serif"> 
<strong>Domain Name: </strong>{{domainname}}<br />
<strong>Website: </strong> www.{{domainname}}<br /><br />
 
<strong>Admin: </strong><a href="https://admin.{{domainname}}:8443/">http://admin.{{domainname}}</a><br />
<strong>User Name: </strong>{{siteuser}}<br />
<strong>Password: </strong>{{domainpassword}}<br /><br />
 
<strong>Emails Web URL: </strong><a href="http://mail.{{domainname}}">http://mail.{{domainname}}</a><br />
<strong>Email: </strong>{{siteuser}}@{{domainname}}<br />
<strong>User Name: </strong>{{siteuser}}<br />
<strong>Password: </strong>{{domainpassword}}<br /><br />
</font></p>
<p><font face="Verdana, Geneva, sans-serif"> 
To Connect emails to outlook go to: <a href="http://wiki.tamshi.co.ke" target="http://wiki.tamshi.co.ke">http://wiki.tamshi.co.ke</a> for details<br />
For other details contact support@dewcis.com
</font></p>
<img src="http://tamshi.co.ke/forxml/powerdby.png" width="483" height="148" alt="tamshi" />
</body>
</html>');

INSERT INTO sys_emails (sys_email_id, sys_email_name, title, details) VALUES (2, 'domain activation', 'Your {{domainname}} activation is active', '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<title>New Domain Activation</title>
</head>

<body>
<img src="http://tamshi.co.ke/forxml/newregistration.png" width="359" height="54" alt="tamshi" /><br />
<p><font face="Trebuchet MS, Arial, Helvetica, sans-serif"> 
<br />Your site www.{{domainname}} has been activated.<br /><br />
<strong>Domain Name: </strong>{{domainname}}<br />
<strong>Website: </strong> www.{{domainname}}<br /><br />

For other details contact support@dewcis.com
</font></p>
<img src="http://tamshi.co.ke/forxml/powerdby.png" width="483" height="148" alt="tamshi" />

</body>
</html>');

