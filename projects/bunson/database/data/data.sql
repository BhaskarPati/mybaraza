INSERT INTO orgs(org_id, currency_id, parent_org_id, org_name, org_sufix, is_default, 
            is_active, logo, pin, details, pcc, sp_id, service_id, sender_name, sms_rate)
VALUES
        (0,1,0,"Bunson Head Office","hq",t,t,"logo.png","","","","","","",2),
        (1,3,0,"Junction","jun",f,t,"logo.png","","","7X4H","","","",2),
        (3,3,0,"Village Market","vm",f,t,"","","","7YC2","","","",2),
        (4,3,0,"Trade Mark","tm",f,t,"logo.png","","","6XM9","","","",2),
        (5,3,0,"US Embassy","use",f,t,"logo.png","","","65B6","","","",2);



