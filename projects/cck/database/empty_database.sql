--approval (workflow) stuff
delete from approval_checklists;
delete from approvals;
delete from sys_emailed;
commit;

--technical stuff
delete from frequency_assignment;
delete from band_assignment;
delete from client_station;
delete from station;
delete from vhf_network;
delete from terrestrial_link;
delete from equipment_approval;
commit;

delete from client_license_status;
delete from clc_history;
delete from tac_history;
commit;
--compliance stuff
delete from client_inspection;
delete from qos_compliance;
delete from lic_conditions_compliance;
commit;
delete from qos_region;

--payment stuff
delete from license_payment_line;
delete from license_payment_header;

--other stuff
delete from installation;
commit;
delete from period_license;
commit;
delete from equipment_approval;
delete from equipment;
commit;

delete from client_director;
--delete from status_client;
commit;
delete from client_director;
delete from client;
commit;

--update client_license set parent_client_license_id = null; commit;
delete from client_license;
commit;

