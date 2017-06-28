CREATE OR REPLACE FUNCTION getAssignedFrequencys(sta_id in integer) RETURN VARCHAR IS
  PRAGMA AUTONOMOUS_TRANSACTION;
  
	myret VARCHAR2(2000);
  
BEGIN
	
	myret := '';      
  
  --GET ALL frequency entries
  FOR myfreq IN (SELECT distinct channel_id, band_assignment_id, amateur_type_id, aircraft_band_type_id FROM frequency_assignment WHERE station_id = sta_id) LOOP
    
    --for band assignments we dont need to LOOP thru all assigned channels
    IF (myfreq.band_assignment_id IS NOT null) THEN
    
      IF(myfreq.amateur_type_id = 1 ) THEN     --FULL AMATEUR
        myret := 'Full Amateur Band';      
      ELSIF(myfreq.amateur_type_id = 2)THEN   --TEMP AMATEUR
        myret := 'Temporary Amateur Band';      
      ELSIF(myfreq.amateur_type_id = 3)THEN   --NOVICE AMATEUR
        myret := 'Novice Amateur Band'; 
      ELSIF(myfreq.aircraft_band_type_id = 1)THEN  --AIRCRAFT HF
        myret := 'Aircraft HF Band'; 
      ELSIF(myfreq.aircraft_band_type_id = 2)THEN  --AIRCRAFT VHF
        myret := 'Aircraft VHF Band'; 
      ELSIF(myfreq.aircraft_band_type_id = 3)THEN  --AIRCRAFT HF + VHF
        myret := 'Aircraft HF + VHF Band'; 
      ELSE
        RETURN 'UNKNOWN Band';
      END IF;
      
      RETURN myret; 
      
    END IF;
    
    
    FOR mychann IN (SELECT channel_id, transmit, receive, units_of_measure FROM channel WHERE channel_id = myfreq.channel_id) LOOP
      IF(mychann.transmit = mychann.receive)THEN
        myret := myret || 'Channel: <b>' || mychann.channel_id || '</b> Simplex: <b>' || mychann.transmit || ' ' || mychann.units_of_measure ||'</b><br>';
      ELSE
        myret := myret || 'Channel: <b>' || mychann.channel_id || '</b> F1: <b>' || mychann.transmit || '</b> F2: <b>' || mychann.receive || ' ' || mychann.units_of_measure ||'</b><br>';
      END IF;
    END LOOP;
    
  END LOOP;
  
	RETURN myret;

EXCEPTION
	WHEN OTHERS THEN
		RETURN 'Error';

END;
/



--get the number of months to the end of the year
create or replace function proratedChargePeriod(from_date IN varchar2) return integer is
	val varchar(2);		--month number
	intval int;
begin
	SELECT to_char(to_date(from_date),'MM') INTO val FROM DUAL;
	intval := cast(val as int);
	
	--if jan, feb or march..
	if(intval <= 3) then	
		return (6 - intval + 1); 
	end if;

	--if less than three months (april,may or june) to start of another financial year..
	if((intval > 3) and (intval < 7)) then	--count the months to jul 1 and add 12 months and return this as the period
		return (6 - intval) + 12 + 1; 
	end if;

	--otherwise (July to Dec) 
	if(intval >= 7) then	--count the months to Dec and add 6 months and return this as the period
		return (12 - intval) + 6 + 1; 
	end if;
	
end;
/




--get the number of months to the end of the year
create or replace function getCreditPeriod(fromdate IN varchar2) return integer is
	val varchar(2);
	intval int;			--month number converted into integer
begin
	--Select to_char(to_date(fromdate),'MM') into val FROM DUAL;
	Select to_char(sysdate,'MM') into val FROM DUAL;
	intval := cast(val as int);
	
	--btwn jan and june
	if(intval <= 6) then	--count the months to Dec and add 6 months and return this as the period
		return (6 - intval);
	else	--btwn jun and dec
	--if((intval >= 6) and (intval < 12)) then	--count the months to jul 1 and add 12 months and return this as the period
		return 6 + (12-intval);
	end if;
		
end;
/




--Arguments: 1=keyfield, 2=logged in user, 3=approvals or phase, 4=filterid if any
CREATE OR REPLACE FUNCTION processChecklist(keyfield IN varchar2, user_id IN varchar2, approval IN varchar2, filter_id IN varchar2) RETURN varchar2 IS
	PRAGMA AUTONOMOUS_TRANSACTION;
	
	--COUNTFEES real;

	--CURSOR cursor2 IS
	--	SELECT periodid FROM periods WHERE periods.isactive = '1';
	--	c4 cursor2%ROWTYPE;

BEGIN

    --OPEN cursor3;
  	--FETCH cursor3 INTO c5;
		
		IF(approval = 'SELECT') THEN
			RETURN 'No Action Selected';
		ELSIF(approval = 'Complied')  THEN
			UPDATE client_checklist SET is_approved = '1', is_rejected = '0', is_pending = '0'
			WHERE client_checklist_id = CAST(keyfield as int);	
			COMMIT;
			RETURN 'Checked ' || keyfield;				
		ELSE
			RETURN 'Unknown Option';
		END IF;
	
	
	--RETURN 'Please Complete Checklist';  
  RETURN 'EOF';
	--CLOSE count_cur;
END;





--Arguments: 1=keyfield, 2=logged in user, 3=approvals or phase, 4=filterid if any
CREATE OR REPLACE FUNCTION upd_Checklist(keyfield IN varchar2, user_id IN varchar2, approval IN varchar2, filter_id IN varchar2) RETURN varchar2 IS
	PRAGMA AUTONOMOUS_TRANSACTION;
	
BEGIN

    --OPEN cursor3;
  	--FETCH cursor3 INTO c5;
		
		IF(approval = 'SELECT') THEN
			RETURN 'No Action Selected';
		ELSIF(approval = 'Complied')  THEN
			UPDATE approval_checklists SET done = '1', updated = current_date, updated_by=CAST(user_id AS INT) WHERE approval_checklist_id = CAST(keyfield as int);	
			COMMIT;
			RETURN 'Checked ' || keyfield;	
		ELSIF(approval = 'Not Complied')  THEN
			UPDATE approval_checklists SET done = '0', updated = current_date, updated_by=CAST(user_id AS INT) WHERE approval_checklist_id = CAST(keyfield as int);	
			COMMIT;
			RETURN 'Undo of ' || keyfield;				
		ELSE
			RETURN 'Unknown Option';
		END IF;
	
	
	--RETURN 'Please Complete Checklist';  
  RETURN 'EOF';
	--CLOSE count_cur;
END;



--Arguments: 1=keyfield, 2=logged in user, 3=approvals or phase, 4=filterid if any
CREATE OR REPLACE FUNCTION approvePhase(keyfield IN varchar2, user_id IN varchar2, approval IN varchar2, filter_id IN varchar2) RETURN varchar2 IS
	PRAGMA AUTONOMOUS_TRANSACTION;

CURSOR checklist_cur IS  
 SELECT  count(client_checklist_id) as chkcount FROM client_checklist
	WHERE (client_phase_id = CAST(keyfield as int)) AND (is_approved != '1');

  rec_checklist checklist_cur%ROWTYPE;

BEGIN
	OPEN checklist_cur;
  	FETCH checklist_cur INTO rec_checklist;

		IF(approval = 'SELECT') THEN
			RETURN 'No Action Selected';

		ELSIF(approval = 'Approved') AND (rec_checklist.chkcount = 0)  THEN
			UPDATE client_phase SET is_approved = '1', is_rejected = '0', is_deffered = '0', is_pending = '0', is_withdrawn = '0', updated_by = CAST(user_id as int)
			WHERE client_phase_id = CAST(keyfield as int);			
			COMMIT;	
			RETURN 'Approved';
		ELSIF(approval = 'Approved') AND (rec_checklist.chkcount > 0)  THEN
			RETURN 'Sorry. There are uncleared checklists';			
		ELSIF(approval = 'Rejected') AND (rec_checklist.chkcount = 0)  THEN
			UPDATE client_phase SET is_approved = '0', is_rejected = '1', is_deffered = '0', is_pending = '0', is_withdrawn = '0', updated_by = CAST(user_id as int)
			WHERE client_phase_id = CAST(keyfield as int);
			COMMIT;	
		ELSIF(approval = 'Workflow') THEN
			UPDATE client_phase SET is_approved = '0', is_rejected = '0', is_deffered = '0', is_pending = '1', is_withdrawn = '0', updated_by = CAST(user_id as int)
			WHERE client_phase_id = CAST(keyfield as int);			
			COMMIT;
			RETURN 'Approved';
		END IF;

		RETURN 'EOF';		--unreachable code segment

	CLOSE checklist_cur;
END;





--each table that needs workflow capability needs to listen on this
--they also need to have the following columns; workflow_table_id, approve_status
CREATE TRIGGER tr_adhoc_workflow BEFORE INSERT OR UPDATE ON approvals
    FOR EACH ROW EXECUTE PROCEDURE adhoc_workflow();

--WORKFLOW APPROVALS
--first we get the
CREATE OR REPLACE FUNCTION adhoc_workflow() RETURNS trigger AS $$
DECLARE
	new_wf_id	integer;		--new workflow id
	parent_wf_id	integer;	--id in the parent table
BEGIN
	IF INSERTING THEN
		'SELECT workflow_table_id INTO parent_wf_id FROM ' || :NEW.table_name || ' WHERE ';
		--check if parent table has workflow_table_id. if yes use it for this workflow
		--if not (workflow_table_id is null in parent table) get sequence the sequence and assign it to :NEW.table_id and the workflow_table_id in parent table (:NEW.table_name)
	END IF;

	IF(NEW.approve_status = 'Completed')THEN
		wfid := nextval('workflow_table_id_seq');
		NEW.workflow_table_id := wfid;

		INSERT INTO approvals (workflow_phase_id, table_name, table_id, approval_level, approval_narrative, to_be_done)
		SELECT workflow_phase_id, TG_TABLE_NAME, wfid, approval_level, phase_narrative, 'Approve - ' || phase_narrative
		FROM vw_workflow_entitys
		WHERE (table_name = TG_TABLE_NAME) AND (entity_id = NEW.entity_id);

		UPDATE approvals SET approve_status = 'Completed' 
		WHERE (table_id = wfid) AND (approval_level = 1);
	END IF;

END;
$$ LANGUAGE plpgsql;




--Arguments: 1=keyfield, 2=logged in user, 3=approvals or phase, 4=filterid if any
CREATE OR REPLACE FUNCTION approveWfPhase(keyfield IN varchar2, user_id IN varchar2, approval IN varchar2, filter_id IN varchar2) RETURN varchar2 IS
	PRAGMA AUTONOMOUS_TRANSACTION;

CURSOR cur_wf_phase IS  
 SELECT  workflow_phase_id FROM workflow_phases
	WHERE (workflow_phase_id = CAST(keyfield as int));
  rec_wf_phase cur_wf_phase%ROWTYPE;

	--CURSOR checklist_cur IS  
	--SELECT  count(client_checklist_id) as chkcount FROM client_checklist
	--WHERE (client_phase_id = CAST(keyfield as int)) AND (is_approved != '1');

	--rec_checklist checklist_cur%ROWTYPE;

BEGIN

	OPEN cur_wf_phase;
  	FETCH cur_wf_phase INTO rec_wf_phase;

	--OPEN checklist_cur;
  	--FETCH checklist_cur INTO rec_checklist;

		IF(approval = 'SELECT') THEN
			RETURN 'No Action Selected';

		ELSIF(approval = 'Approved') THEN		--AND (rec_checklist.chkcount = 0)
			UPDATE approvals SET 
			UPDATE workflow_phases SET is_done = '1' WHERE workflow_phase_id = rec_wf_phase.workflow_phase_id;			
			COMMIT;	
			RETURN 'Approved';
		--ELSIF(approval = 'Approved') THEN		--AND (rec_checklist.chkcount > 0) 
		--	UPDATE workflow_phases SET is_done = '1' WHERE workflow_phase_id = rec_wf_phase.workflow_phase_id;			
		--	COMMIT;	
		--	RETURN 'Approved';
		ELSIF(approval = 'Rejected') AND (rec_checklist.chkcount = 0)  THEN
			UPDATE client_phase SET is_approved = '0', is_rejected = '1', is_deffered = '0', is_pending = '0', is_withdrawn = '0', updated_by = CAST(user_id as int)
			WHERE client_phase_id = CAST(keyfield as int);
			COMMIT;	
		ELSIF(approval = 'Workflow') THEN
			UPDATE client_phase SET is_approved = '0', is_rejected = '0', is_deffered = '0', is_pending = '1', is_withdrawn = '0', updated_by = CAST(user_id as int)
			WHERE client_phase_id = CAST(keyfield as int);			
			COMMIT;
			RETURN 'Workflow';
		END IF;

		RETURN 'EOF';		--unreachable code segment

	CLOSE checklist_cur;
END;






--Arguments: 1=keyfield, 2=logged in user, 3=approvals or phase, 4=filterid if any
CREATE OR REPLACE FUNCTION del_client_station(cli_sta_id IN varchar2, user_id IN varchar2, approval IN varchar2, filter_id IN varchar2) RETURN VARCHAR2 IS
	PRAGMA AUTONOMOUS_TRANSACTION;

	sta_chrg_id 	integer;

	BEGIN	 

		SELECT station_charge_id INTO sta_chrg_id FROM client_station WHERE client_station_id = cast(cli_sta_id as integer);

		IF(approval = 'SELECT') THEN
			RETURN 'No Action Selected';
		ELSIF approval = 'Delete' THEN
			DELETE FROM client_station where client_station_id = cast(cli_sta_id as integer);
			DELETE FROM station where vhf_network_id = cast(filter_id as integer) AND station_charge_id = sta_chrg_id;
			COMMIT;
		END IF;
	RETURN 'Stations Deleted';
END;
/



--Arguments: 1=keyfield, 2=logged in user, 3=approvals or phase, 4=filterid if any
CREATE OR REPLACE FUNCTION process_CLC(cli_lic_id IN varchar2, user_id IN varchar2, approval IN varchar2, filter_id IN varchar2) RETURN VARCHAR2 IS
	PRAGMA AUTONOMOUS_TRANSACTION;

	tab_id		integer;
	clc         integer;

	BEGIN

		SELECT workflow_table_id,clc_id INTO tab_id,clc FROM client_license WHERE client_license_id = CAST(cli_lic_id AS INT);

		IF approval = 'SELECT' THEN
			RETURN 'NO SELECTION MADE';

		ELSIF approval = 'Add' THEN
			UPDATE client_license SET clc_id = CAST(filter_id AS int) WHERE client_license_id = CAST(cli_lic_id AS int);
			COMMIT;
			RETURN 'Added '|| cli_lic_id || ' to CLC :' || filter_id ;

		ELSIF (approval = 'Approved' AND clc IS NOT NULL) THEN			
			--log clc
			INSERT INTO clc_history(client_license_id,clc_id,is_approved) VALUES(CAST(cli_lic_id as int),clc,'1');
			COMMIT;
			--SCHEDULE EMAIL TO CLIENT
			INSERT INTO sys_emailed (sys_email_id, table_id, table_name, email_type) VALUES (50, tab_id, 'CLIENT_LICENSE', 5);		
			COMMIT;
			RETURN 'Application ' || approval;

		ELSIF (approval = 'Rejected' AND clc IS NOT NULL) THEN
			--clear from clc
			UPDATE client_license SET clc_id = NULL	WHERE client_license_id = CAST(cli_lic_id as int);
			COMMIT;
			--log clc
			INSERT INTO clc_history(client_license_id,clc_id, is_rejected) VALUES(CAST(cli_lic_id as int),clc,'1');
			COMMIT;
			--SCHEDULE EMAIL TO CLIENT
			INSERT INTO sys_emailed (sys_email_id, table_id, table_name, email_type) VALUES (51, tab_id, 'CLIENT_LICENSE', 5);		
			COMMIT;
			RETURN 'Application ' || approval;

		ELSIF (approval = 'Deffered' AND clc IS NOT NULL) THEN
			--clear from clc
			UPDATE client_license SET clc_id = NULL	WHERE client_license_id = CAST(cli_lic_id as int);
			COMMIT;
			--log clc
			INSERT INTO clc_history(client_license_id,clc_id,is_differed) VALUES(CAST(cli_lic_id as int),clc,'1');
			COMMIT;
			--SCHEDULE EMAIL TO CLIENT
			INSERT INTO sys_emailed (sys_email_id, table_id, table_name, email_type) VALUES (52, tab_id, 'CLIENT_LICENSE', 5);		
			COMMIT;
			RETURN 'Application ' || approval;

		ELSIF (approval = 'Withdrawn' AND clc IS NOT NULL) THEN
			--clear from clc
			UPDATE client_license SET clc_id = NULL	WHERE client_license_id = CAST(cli_lic_id as int);
			COMMIT;
			--log clc
			INSERT INTO clc_history(client_license_id,clc_id,is_withdrawn) VALUES(CAST(cli_lic_id as int),clc,'1');
			COMMIT;
			--SCHEDULE EMAIL TO CLIENT
			INSERT INTO sys_emailed (sys_email_id, table_id, table_name, email_type) VALUES (53, tab_id, 'CLIENT_LICENSE', 5);		
			COMMIT;
			RETURN 'Application ' || approval;
		ELSIF clc IS NULL THEN
			RETURN 'CLC ID IS NULL. Make sure the application has been added to a specific clc first';
		END IF;

		RETURN 'UNREACHABLE';
END;
/




CREATE OR REPLACE FUNCTION process_Board(cli_lic_id IN varchar2, user_id IN varchar2, approval IN varchar2, filter_id IN varchar2) RETURN VARCHAR2 IS
	PRAGMA AUTONOMOUS_TRANSACTION;

	tab_id		integer;
	brd         integer;

	BEGIN

		SELECT workflow_table_id,board_meeting_id INTO tab_id,brd FROM client_license WHERE client_license_id = CAST(cli_lic_id AS INT);

		IF approval = 'SELECT' THEN
			RETURN 'NO SELECTION MADE';

		ELSIF approval = 'Add' THEN
			UPDATE client_license SET board_meeting_id = CAST(filter_id AS int) WHERE client_license_id = CAST(cli_lic_id AS int);
			COMMIT;
			RETURN 'Added '|| cli_lic_id || ' for Board Consideration :' || filter_id ;

		ELSIF (approval = 'Approved' AND brd IS NOT NULL) THEN			
			--log clc
			--INSERT INTO clc_history(client_license_id,clc_id,is_approved) VALUES(CAST(cli_lic_id as int),clc,'1');
			--COMMIT;
			--SCHEDULE EMAIL TO CLIENT
			INSERT INTO sys_emailed (sys_email_id, table_id, table_name, email_type) VALUES (50, tab_id, 'CLIENT_LICENSE', 5);		
			COMMIT;
			RETURN 'Board Decision: ' || approval;

		ELSIF (approval = 'Rejected' AND brd IS NOT NULL) THEN
			--clear from clc
			UPDATE client_license SET board_meeting_id = NULL WHERE client_license_id = CAST(cli_lic_id as int);
			COMMIT;
			--log clc
			--INSERT INTO clc_history(client_license_id,clc_id, is_rejected) VALUES(CAST(cli_lic_id as int),clc,'1');
			--COMMIT;
			--SCHEDULE EMAIL TO CLIENT
			INSERT INTO sys_emailed (sys_email_id, table_id, table_name, email_type) VALUES (51, tab_id, 'CLIENT_LICENSE', 5);		
			COMMIT;
			RETURN 'Boad Decision: ' || approval;

		ELSIF brd IS NULL THEN
			RETURN 'BOARD MEETING ID IS NULL. Make sure the application has been added to a specific board meeting first';
		END IF;

		RETURN 'UNREACHABLE';
END;
/





CREATE OR REPLACE FUNCTION getPhaseEmail(ent_typ_id IN INTEGER) RETURN VARCHAR2 IS
    PRAGMA AUTONOMOUS_TRANSACTION;
		email_list		VARCHAR(300);

	BEGIN
		email_list := null;

		FOR myrec IN 
			(SELECT entitys.primary_email
			FROM entitys 
			INNER JOIN entity_subscriptions ON entitys.entity_id = entity_subscriptions.entity_id
			WHERE entity_subscriptions.entity_type_id = ent_typ_id) LOOP

			IF (email_list is null) THEN
				email_list := myrec.primary_email;
			ELSE
				email_list := email_list || ', ' || myrec.primary_email;
			END IF;

		END LOOP;

	RETURN email_list;

END;
/






--deprecated. syntax is ok but semantics not quite quite
CREATE OR REPLACE FUNCTION getChannelID(f1 in integer, f2 in integer, units in varchar) RETURN integer IS
PRAGMA AUTONOMOUS_TRANSACTION;

	chan_id int;
	
BEGIN
	
	--may return more than one channel id. MAX() is used as a stop-gap measure aka quick fix
	SELECT min(channel_id) INTO chan_id FROM channel WHERE decode(units_of_measure,'GHz', transmit*100, 'KHz', transmit/100, transmit) >= f1 AND decode(units_of_measure,'GHz', receive*1000, 'KHz', receive/100, receive) <= f2;

	RETURN chan_id;
  
END;
/


CREATE OR REPLACE FUNCTION getFootNotes(transmit in integer, receive in integer) RETURN varchar IS
PRAGMA AUTONOMOUS_TRANSACTION;

	footnote_html varchar(1000);
	
BEGIN
	
	--select all footnotes with u
  FOR footnote_rec IN (SELECT footnote_definition_id, footnote_definition, footnote_description FROM vw_channel_footnotes WHERE lower_limit <= transmit AND upper_limit >= receive) LOOP
    footnote_html := footnote_html || '<b>' || footnote_rec.footnote_definition || ': </b>' || footnote_rec.footnote_description || '<br>';
  END LOOP;
  
	RETURN footnote_html;
  
END;
/



--LAND MOBILE STUFF
CREATE OR REPLACE FUNCTION countBase(cli_lic_id IN integer) RETURN integer IS
	PRAGMA AUTONOMOUS_TRANSACTION;
	myret int;
BEGIN
	select count(station_id) into myret
	from station
	inner join vhf_network on station.vhf_network_id = vhf_network.vhf_network_id
	where (vhf_network.client_license_id = cli_lic_id) and ((station.station_charge_id = 4) or (station.station_charge_id = 5));		
	RETURN myret;
END;
/


CREATE OR REPLACE FUNCTION countPortable(cli_lic_id IN integer) RETURN integer IS
	PRAGMA AUTONOMOUS_TRANSACTION;
	myret int;
BEGIN
	select count(station_id) into myret
	from station
	inner join vhf_network on station.vhf_network_id = vhf_network.vhf_network_id
	where (vhf_network.client_license_id = cli_lic_id) and ((station.station_charge_id = 1) or (station.station_charge_id = 3));			
	RETURN myret;
END;
/


CREATE OR REPLACE FUNCTION countMobile(cli_lic_id IN integer) RETURN integer IS
	PRAGMA AUTONOMOUS_TRANSACTION;
	myret int;
BEGIN
	select count(station_id) into myret
	from station
	inner join vhf_network on station.vhf_network_id = vhf_network.vhf_network_id
	where (vhf_network.client_license_id = cli_lic_id) and ((station.station_charge_id = 2) or (station.station_charge_id = 6));			
	RETURN myret;
	
END;
/




CREATE OR REPLACE FUNCTION getNumberOfFrequencies(sta_id in integer, typ in varchar) RETURN integer IS
	PRAGMA AUTONOMOUS_TRANSACTION;

	num_frequencies int;
	
BEGIN
	
	num_frequencies := 0;

	IF (typ = 'station') THEN
		FOR my_rec in 
			(select frequency_assignment.station_id, decode(coalesce(channel.receive,0) - coalesce(channel.transmit,0),0,1,2) as num 
			from frequency_assignment 
			inner join channel on frequency_assignment.channel_id = channel.channel_id
			where frequency_assignment.station_id = sta_id)
		LOOP
			num_frequencies := num_frequencies + my_rec.num;
		END LOOP;

		RETURN num_frequencies;

	ELSIF (typ = 'p2p') THEN
		FOR my_rec in 
			(select frequency_assignment.terrestrial_link_id, decode(coalesce(channel.receive,0) - coalesce(channel.transmit,0),0,1,2) as num 
			from frequency_assignment 
			inner join channel on frequency_assignment.channel_id = channel.channel_id
			where frequency_assignment.terrestrial_link_id = sta_id)
		LOOP
			num_frequencies := num_frequencies + my_rec.num;
		END LOOP;

		RETURN num_frequencies;
	END IF;
  
END;
/



CREATE OR REPLACE FUNCTION getNetworkFrequencies(net_id in integer) RETURN integer IS
	PRAGMA AUTONOMOUS_TRANSACTION;

	num_frequencies int;
	
BEGIN
	
	num_frequencies := 0;

	FOR my_rec in 
		(select frequency_assignment.station_id, decode(coalesce(channel.receive,0) - coalesce(channel.transmit,0),0,1,2) as num 
		from frequency_assignment 
		inner join channel on frequency_assignment.channel_id = channel.channel_id
		where frequency_assignment.vhf_network_id = net_id)
	LOOP
		num_frequencies := num_frequencies + my_rec.num;
	END LOOP;

	RETURN num_frequencies;
  
END;
/


--get the number of bands (not channels) assigend eg the number of Aircraft HF, number of full amateur bands, etc
CREATE OR REPLACE FUNCTION getNumberOfBands(station_id in integer,payload_id in integer, isamateur in varchar, isaircraft in varchar) RETURN integer IS
PRAGMA AUTONOMOUS_TRANSACTION;

	num_of_bands int;
	
BEGIN
	
	num_of_bands := 0;

	if(isaircraft = '1') then
		select count(aircraft_band_type_id) into num_of_bands from frequency_assignment where station_id = station_id and aircraft_band_type_id = payload_id;
	elsif (isamateur = '1') then
		select count(amateur_type_id) into num_of_bands from frequency_assignment where station_id = station_id and amateur_type_id = payload_id;
	end if;

	RETURN num_of_bands;
  
END;
/


CREATE OR REPLACE FUNCTION count_Network_Stations(vhf_net_id in integer) RETURN varchar IS
PRAGMA AUTONOMOUS_TRANSACTION;
	myret int;
	summary varchar(1000);
BEGIN
	summary := '';
	for myrec in (select number_of_requested_stations, station_charge_name
				from client_station 
				inner join station_charge on client_station.station_charge_id = station_charge.station_charge_id 
				where client_station.vhf_network_id = vhf_net_id) loop
		summary := summary  || myrec.number_of_requested_stations || ' ' || myrec.station_charge_name || '<br>  '; 
	end loop;

	RETURN summary;

EXCEPTION
	WHEN OTHERS THEN
		RETURN 'error';

END;
/

--NEW License application for an existing applicant
--Arguments: 1=keyfield, 2=logged in user, 3=approvals or phase, 4=filterid if any
CREATE OR REPLACE FUNCTION manage_application(lic_id IN varchar2, use_id IN varchar2, approval IN varchar2, cli_id IN varchar2) RETURN VARCHAR2 IS
	PRAGMA AUTONOMOUS_TRANSACTION;

  BEGIN
  
	IF approval = 'SELECT' THEN
  
		RETURN 'No Selection Made';
    
	ELSIF approval = 'ADD' THEN

		--THIS IS NEEDED FOR new applicants from OLD CCK DATABASE who are not in our imis table 'CLIENT'
		-- 	CURSOR sms_use_cur IS		
		-- 	SELECT clientid,clientname from clients where clientid=cli_id;
		-- 
		-- 	rec sms_use_cur%ROWTYPE;
		-- 
		-- 	BEGIN	 
		-- 		OPEN sms_use_cur;
		-- 		FETCH sms_use_cur INTO rec;
		--  
		-- 	  --!!! IF NOT IN CLIENTS TABLE and LICENSE = FSM (typeid=16) insert this person into clients table so that he is visible at clientlicenses
		-- 	  IF (sms_use_cur%NOTFOUND) THEN
		--       INSERT INTO clients(clientname,clienttypeid,clientcategoryid,licenseid,countryid,filenumber,address,postalcode,email,town)
		-- 			select sms_users.use_name,43,48,cast(lic_id as int),'KE',sms_users.use_birth_location,sms_users.use_mail_address,sms_users.use_mail_postcode,sms_users.use_mail_email,'Nairobi'
		-- 			from sms_users
		-- 			where use_id=cli_id;
		--       COMMIT;
		-- 	  END IF;
			
		INSERT INTO client_license(license_id,client_id,created_by) VALUES (CAST(lic_id AS int), CAST(cli_id AS int), CAST(use_id AS int));
		COMMIT;
    
		RETURN ' New Application Successful';
    
	END IF;

END;
/






--Arguments: 1=keyfield, 2=logged in user, 3=approvals or phase, 4=filterid if any
CREATE OR REPLACE FUNCTION processNotification(keyfield IN varchar2, user_id IN varchar2, approval IN varchar2, filter_id IN varchar2) RETURN varchar2 IS
	PRAGMA AUTONOMOUS_TRANSACTION;

	tab_id		integer;	

	BEGIN

		SELECT workflow_table_id INTO tab_id FROM client_license WHERE client_license_id = CAST(keyfield AS INT);
   
		IF(approval = 'SELECT') THEN
			RETURN 'No Action Selected';

		ELSIF(approval = 'Submit')  THEN
			INSERT INTO sys_emailed (sys_email_id, table_id, table_name, email_type) VALUES (61, tab_id, 'CLIENT_LICENSE', 5);		
			COMMIT;
			
      UPDATE client_license SET is_offer_sent = '1' WHERE client_license_id = CAST(keyfield AS INT);
      COMMIT;
      
      RETURN 'Queued ' || keyfield;				
		ELSE
			RETURN 'Unknown Option';
		END IF;
	
	
	--RETURN 'Please Complete Checklist';  
  RETURN 'UNREACHABLE';
	--CLOSE count_cur;
END;






--Activate License
CREATE OR REPLACE FUNCTION processLicense(keyfield IN varchar2, user_id IN varchar2, approval IN varchar2, filter_id IN varchar2) RETURN varchar2 IS
	PRAGMA AUTONOMOUS_TRANSACTION;
    tab_id    integer;
	BEGIN	
  
    SELECT workflow_table_id INTO tab_id FROM client_license WHERE client_license_id = CAST(keyfield AS int);

		IF(approval = 'SELECT') THEN
			RETURN 'No Action Selected';

		ELSIF approval='Activate' THEN
      
			UPDATE client_license set is_active='1' WHERE client_license_id = CAST(keyfield AS int);
      
			INSERT INTO period_license(period_id,client_license_id,status_license_id,status_client_id) VALUES(1,CAST(keyfield AS int),3,2);
			COMMIT;
      
			INSERT INTO sys_emailed (sys_email_id, table_id, table_name, email_type) VALUES (71, tab_id, 'PERIOD_LICENSE', 50);		
			COMMIT;
			
			RETURN 'License Activated and Email Sent';
      
		ELSE
			RETURN 'UNREACHABLE';
      
		END IF;
END;
/


















--Arguments: 1=keyfield, 2=logged in user, 3=approvals or phase, 4=filterid if any
CREATE OR REPLACE FUNCTION process_TAC(cli_lic_id IN varchar2, user_id IN varchar2, approval IN varchar2, filter_id IN varchar2) RETURN VARCHAR2 IS
	PRAGMA AUTONOMOUS_TRANSACTION;

	tab_id		integer;
	tac         integer;
	cert_date	date;

	BEGIN

		SELECT workflow_table_id,tac_id INTO tab_id,tac FROM client_license WHERE client_license_id = CAST(cli_lic_id AS INT);

		SELECT add_months(TO_CHAR(SYSDATE, 'DD/Mon/YYYY'), 6) INTO cert_date FROM dual;

		IF approval = 'SELECT' THEN
			RETURN 'NO SELECTION MADE';

		ELSIF approval = 'Add' THEN
			UPDATE client_license SET tac_id = CAST(filter_id AS int) WHERE client_license_id = CAST(cli_lic_id AS int);
			COMMIT;
			RETURN 'Added '|| cli_lic_id || ' to CLC :' || filter_id ;

		ELSIF (approval = 'Approved' AND tac IS NOT NULL) THEN			
			--log tac
			INSERT INTO tac_history(client_license_id,tac_id) VALUES(CAST(cli_lic_id as int),tac);
			COMMIT;
			--SCHEDULE EMAIL TO CLIENT
			INSERT INTO sys_emailed (sys_email_id, table_id, table_name, email_type) VALUES (50, tab_id, 'CLIENT_LICENSE', 5);		
			COMMIT;
						
			UPDATE client_license SET tac_approval_date = SYSDATE, certification_date = cert_date WHERE client_license_id = CAST(cli_lic_id AS INT);
			COMMIT;
					
			--ADD EQUIPMENT
			INSERT INTO equipment(equipment_type_id, equipment_make, equipment_model,supplier_name) 
			SELECT equipment_type_id, make, model, client_name 
				FROM vw_equipment_approval
				WHERE  client_license_id = CAST(cli_lic_id AS int) AND rownum = 1;
				COMMIT;
			UPDATE equipment_approval SET is_ta_approved = '1' WHERE client_license_id = CAST(cli_lic_id AS int);
			COMMIT;
	
			RETURN 'Application ' || approval;

		ELSIF (approval = 'Rejected' AND tac IS NOT NULL) THEN
			--clear from tac
			UPDATE client_license SET tac_id = NULL	WHERE client_license_id = CAST(cli_lic_id as int);
			COMMIT;
			--log tac
			INSERT INTO tac_history(client_license_id,tac_id) VALUES(CAST(cli_lic_id as int),tac);
			COMMIT;
			--SCHEDULE EMAIL TO CLIENT
			INSERT INTO sys_emailed (sys_email_id, table_id, table_name, email_type) VALUES (51, tab_id, 'CLIENT_LICENSE', 5);		
			COMMIT;
			RETURN 'Application ' || approval;


		ELSIF tac IS NULL THEN
			RETURN 'TAC ID IS NULL. Make sure the application has been added to a specific tac first';
		END IF;

		RETURN 'UNREACHABLE';
END;
/















CREATE OR REPLACE FUNCTION processNumbering (keyfield IN varchar2, user_id IN varchar2, approval IN varchar2, filter_id IN varchar2) RETURN VARCHAR2 IS
	PRAGMA AUTONOMOUS_TRANSACTION;

	numberassigned varchar2(240);
	
	CURSOR c1 IS
		SELECT CLIENTNAME,clientid			
		FROM vwallchecklists 
		WHERE clientphaseid = CAST(myval4 AS int);
		rc1 c1%ROWTYPE;
		

	BEGIN

	OPEN c1;
	FETCH c1 INTO rc1;

	IF(myval3 = 'CELL_PHONE') THEN
		SELECT CELLPHONERANGE INTO numberassigned FROM cellphones WHERE cellphoneid = CAST(myval1 AS int);
		UPDATE cellphones  SET assigned = '1',dateassigned = SYSDATE,clientid = rc1.clientid WHERE cellphoneid = CAST(myval1 AS int);

		INSERT INTO assignednumbers (CLIENTID,booked,datebooked,RESOURCEASSIGNED,resourceid)
		VALUES(rc1.clientid,'1',SYSDATE,'cellphones',numberassigned);
		COMMIT;
		RETURN 'Assigned';
	END IF;
  
-- 	IF(myval3 = 'FREE_PHONE') THEN
-- 		SELECT CELLPHONERANGE INTO numberassigned FROM freephone WHERE freephoneid = CAST(myval1 AS int);
-- 			UPDATE freephone  SET assigned = '1',dateassigned = SYSDATE,clientid = CAST(myval4 AS int) 
-- 			WHERE freephoneid = CAST(myval1 AS int);
-- 			INSERT INTO assignednumbers (CLIENTID,booked,datebooked,RESOURCEASSIGNED,resourceid) 
-- 		VALUES(rc1.clientid,'1',SYSDATE,'Free Phone',numberassigned);
-- 		COMMIT;
-- 		RETURN 'Assigned';
-- 	END IF;

-- 	IF(myval3 = 'premiumphone') THEN
-- 		SELECT CELLPHONERANGE INTO numberassigned FROM freephone WHERE freephoneid = CAST(myval1 AS int);
-- 			UPDATE freephone  SET assigned = '1',dateassigned = SYSDATE,clientid = CAST(myval4 AS int) 
-- 			WHERE freephoneid = CAST(myval1 AS int);
-- 			INSERT INTO assignednumbers (CLIENTID,booked,datebooked,RESOURCEASSIGNED,resourceid) 
-- 		VALUES(rc1.clientid,'1',SYSDATE,'Premium Phone',numberassigned);
-- 		COMMIT;
-- 		RETURN 'Assigned';
-- 	END IF;
--   
--   
-- 	IF(myval3 = 'Identification') THEN
-- 		SELECT IDNUMBER INTO numberassigned FROM issueridentification WHERE issueridentificationid = CAST(myval1 AS int);
-- 			UPDATE issueridentification  SET assigned = '1',dateassigned = SYSDATE,clientid = rc1.clientid 
-- 			WHERE issueridentificationid = CAST(myval1 AS int);
-- 			INSERT INTO assignednumbers (CLIENTID,booked,datebooked,RESOURCEASSIGNED,resourceid) 
-- 		VALUES(rc1.clientid,'1',SYSDATE,'Identification',numberassigned);
-- 		COMMIT;
-- 		RETURN 'Assigned';
-- 	END IF;
-- 
-- 	IF(myval3 = 'imsi') THEN
-- 		SELECT imsi INTO numberassigned FROM imsi WHERE imsiid = CAST(myval1 AS int);
-- 			UPDATE imsi  SET assigned = '1',dateassigned = SYSDATE,clientid = rc1.clientid 
-- 			WHERE imsiid = CAST(myval1 AS int);
-- 			INSERT INTO assignednumbers (CLIENTID,booked,datebooked,RESOURCEASSIGNED,resourceid)
-- 		VALUES(rc1.clientid,'1',SYSDATE,'imsi',numberassigned);
-- 		COMMIT;
-- 		RETURN 'Assigned';
-- 	END IF;
-- 
-- 	IF(myval3 = 'ispc') THEN
-- 		SELECT ISPC INTO numberassigned FROM ispc WHERE ispcID = CAST(myval1 AS int);
-- 			UPDATE ispc  SET assigned = '1',dateassigned = SYSDATE,clientid = rc1.clientid ,ispcoperator = rc1.clientname
-- 			WHERE ispcID = CAST(myval1 AS int);
-- 			INSERT INTO assignednumbers (CLIENTID,booked,datebooked,RESOURCEASSIGNED,resourceid) 
-- 		VALUES(rc1.clientid,'1',SYSDATE,'ispc',numberassigned);
-- 		COMMIT;
-- 		RETURN 'Assigned';
-- 	END IF;
--   
-- 	IF(myval3 = 'fixedline') THEN
-- 	SELECT NUMBERASSIGNED2 INTO numberassigned FROM fixedline WHERE fixedlineid = CAST(myval1 AS int);
-- 			UPDATE fixedline  SET assigned = '1',dateassigned = SYSDATE,clientid = rc1.clientid ,ASSIGNEE = rc1.clientname
-- 			WHERE fixedlineid = CAST(myval1 AS int);
-- 			INSERT INTO assignednumbers (CLIENTID,booked,datebooked,RESOURCEASSIGNED,resourceid) 
-- 		VALUES(rc1.clientid,'1',SYSDATE,'Fixed Line',numberassigned);
-- 		COMMIT;
-- 		RETURN 'Assigned';
-- 	END IF;
-- 	
-- 		IF(myval3 = 'colourcode') THEN
-- 	SELECT COLOURCODE INTO numberassigned FROM colourcodes WHERE COLOURCODEID = CAST(myval1 AS int);
-- 			UPDATE colourcodes  SET ASSIGNED = '1',dateassigned = SYSDATE,clientid = rc1.clientid ,ASSIGNEE = rc1.clientname
-- 			WHERE COLOURCODEID = CAST(myval1 AS int);
-- 			INSERT INTO assignednumbers (CLIENTID,booked,datebooked,RESOURCEASSIGNED,resourceid) 
-- 		VALUES(rc1.clientid,'1',SYSDATE,'colourcode',numberassigned);
-- 		COMMIT;
-- 		RETURN 'Assigned';
-- 	END IF;
-- 
-- 	IF(myval3 = 'sid') THEN
-- 		SELECT SYSTEMIDENTIFIER INTO numberassigned FROM systemidentifier WHERE systemidentifierid = CAST(myval1 AS int);
-- 				UPDATE systemidentifier  SET ASSIGNED = '1',dateassigned = SYSDATE,clientid = rc1.clientid ,ASSIGNEE = rc1.clientname
-- 				WHERE systemidentifierid = CAST(myval1 AS int);
-- 				INSERT INTO assignednumbers (CLIENTID,booked,datebooked,RESOURCEASSIGNED,resourceid) 
-- 			VALUES(rc1.clientid,'1',SYSDATE,'sid',numberassigned);
-- 			COMMIT;
-- 			RETURN 'Assigned';
-- 	END IF;

	RETURN 'Unreachable Code';
END;
 





CREATE OR REPLACE FUNCTION processInstallation(keyfield IN varchar2, user_id IN varchar2, approval IN varchar2, filter_id IN varchar2) RETURN VARCHAR2 IS
	PRAGMA AUTONOMOUS_TRANSACTION;
	BEGIN
	IF(approval = 'SELECT')  THEN
		RETURN 'NO OPTION SELECTED';
	ELSIF(approval = 'Approved')  THEN
		UPDATE installation SET is_approved = '1',is_rejected='0' WHERE installation_id = CAST(keyfield as int);
		COMMIT;
		RETURN approval;	
	ELSIF(approval = 'Rejected')  THEN
		UPDATE installation SET is_approved = '0', is_rejected='1' WHERE installation_id = CAST(keyfield as int);
		COMMIT;
		RETURN approval;
	END IF;
	
	RETURN 'UNREACHABLE';
END;
/






--END OF YEAR ROUTINE
-- CREATE OR REPLACE FUNCTION newYearRoutine(keyfield IN varchar2, user_id IN varchar2, approval IN varchar2, filter_id IN varchar2) RETURN VARCHAR2 IS
-- 	PRAGMA AUTONOMOUS_TRANSACTION;
-- 	BEGIN
-- 
-- 	--get license stuff
-- 	SELECT application_fee INTO app_fee FROM license 
-- 		INNER JOIN client_license ON license.license_id = client_license.license_id
-- 		WHERE client_license.workflow_table_id = :NEW.table_id;
-- 
-- 	IF(approval = 'SELECT')  THEN
-- 		RETURN 'NO OPTION SELECTED';
-- 	ELSIF(approval = 'EMAIL')  THEN
-- 		INSERT INTO sys_emailed (sys_email_id, table_id, table_name, email_type) VALUES (72, tab_id, 'PERIOD_LICENSE', 50);
-- 		COMMIT;
-- 		RETURN approval;
-- 	ELSIF(approval = 'BILL')  THEN
-- 		--THEN INSERT INTO PAYMENTS TABLE
-- 		SELECT license_payment_header_id_seq.nextval into pay_header_id from dual;						
-- 		--HEADER 
-- 		INSERT INTO license_payment_header(license_payment_header_id,client_license_id,workflow_phase_id,workflow_table_id,description) 
-- 			VALUES(pay_header_id,cli_lic_id,nxt_phase_id,:NEW.table_id,'ANNUAL LICENSE FEE');
-- 			COMMIT;
-- 		
-- 		--LINES
-- 		INSERT INTO license_payment_line(license_payment_header_id,product_code,description,amount) 
-- 			VALUES(pay_header_id,'0FFE42C843354755BE24AD5969EDCB0A','Initial Fee (KES)', annual_fee);
-- 			COMMIT;					
-- 
-- 		RETURN approval;				
-- 	END IF;
-- 	
-- 	RETURN 'UNREACHABLE';
-- END;
-- /










--this REPLACES generateinvoices (Original). Generates invoices per licenses
CREATE OR REPLACE FUNCTION generateAnnualPayments(lic_id IN varchar2, user_id IN varchar2, approval IN varchar2, period_id IN varchar2) RETURN varchar2 IS

	PRAGMA AUTONOMOUS_TRANSACTION;  

  pay_header_id   integer;
BEGIN


	IF(approval = 'SELECT')  THEN
		RETURN 'NO OPTION SELECTED';
	END IF;
	
	SELECT license_payment_header_id_seq.nextval into pay_header_id from dual;

	--IF LAND MOBILE 
	IF lic_id = '12' THEN
		
		FOR rec_network IN (select vhf_network.vhf_network_id, client_license.workflow_table_id, client_license.client_license_id, sum(amount) as aggregate_charge
							from station
							inner join vhf_network on station.vhf_network_id = vhf_network.vhf_network_id
							inner join client_license on vhf_network.client_license_id = client_license.client_license_id
							--inner join period_license on period_license.client_license_id = client_license.client_license_id
							inner join station_charge on station.station_charge_id = station_charge.station_charge_id			
							group by vhf_network.vhf_network_id, client_license.workflow_table_id, client_license.client_license_id) LOOP
						
			
			INSERT INTO license_payment_header(license_payment_header_id,client_license_id,workflow_table_id,description) 
				VALUES(pay_header_id, rec_network.client_license_id, rec_network.workflow_table_id, 'ANNUAL FEE');
			COMMIT;
			
			INSERT INTO license_payment_line(license_payment_header_id, product_code, description, amount) 
				VALUES(pay_header_id, '0FFE42C843354755BE24AD5969EDCB0A', 'Annual Fee (KES)', rec_network.aggregate_charge);
			COMMIT;
			
			--SEND NOTIFICATIONS			
			INSERT INTO sys_emailed (sys_email_id, table_id, table_name, email_type) VALUES (72, rec_network.workflow_table_id, 'PERIOD_LICENSE', 50);
			COMMIT;	

		END LOOP;

	ELSIF lic_id = '8' THEN		--AIRCRAFT

		FOR rec_aircraft IN	(select station.client_license_id, client_license.workflow_table_id, amount as aggregate_charge
							from station							
							inner join client_license on station.client_license_id = client_license.client_license_id
							--inner join period_license on period_license.client_license_id = client_license.client_license_id
							inner join station_charge on station.station_charge_id = station_charge.station_charge_id
							where client_license.license_id = CAST(lic_id AS INT)) LOOP					
			
			INSERT INTO license_payment_header(license_payment_header_id,client_license_id,workflow_table_id,description) 
				VALUES(pay_header_id, rec_aircraft.client_license_id, rec_aircraft.workflow_table_id, 'ANNUAL FEE');
			COMMIT;
			
			INSERT INTO license_payment_line(license_payment_header_id, product_code, description, amount) 
				VALUES(pay_header_id, '0FFE42C843354755BE24AD5969EDCB0A', 'Annual Fee (KES)', rec_aircraft.aggregate_charge);
			COMMIT;
			
			--SEND NOTIFICATIONS			
			INSERT INTO sys_emailed (sys_email_id, table_id, table_name, email_type) VALUES (72, rec_aircraft.workflow_table_id, 'PERIOD_LICENSE', 50);
			COMMIT;	

		END LOOP;
    
	ELSIF lic_id = '131' OR lic_id = '132' THEN

		FOR my_lic IN (SELECT period_license.client_license_id, client_license.workflow_table_id, (period_license.annual_fee_due) as aggregate_charge
				FROM period_license
				INNER JOIN client_license ON period_license.client_license_id = client_license.client_license_id
				INNER JOIN license ON client_license.license_id = license.license_id
				WHERE license.license_id = CAST(lic_id AS INT)) LOOP

				INSERT INTO license_payment_header(license_payment_header_id,client_license_id,workflow_table_id,description) 
					VALUES(pay_header_id, my_lic.client_license_id, my_lic.workflow_table_id, 'ANNUAL FEE');
				COMMIT;
				
				INSERT INTO license_payment_line(license_payment_header_id, product_code, description, amount) 
					VALUES(pay_header_id, '0FFE42C843354755BE24AD5969EDCB0A', 'Annual Fee (KES)', my_lic.aggregate_charge);
				COMMIT;

				--SEND NOTIFICATIONS			
				INSERT INTO sys_emailed (sys_email_id, table_id, table_name, email_type) VALUES (72, my_lic.workflow_table_id, 'PERIOD_LICENSE', 50);
				COMMIT;	
			END LOOP;
  
		ELSIF lic_id = '136' OR lic_id = '137' THEN  --vsat

			FOR my_lic IN (SELECT period_license.client_license_id, client_license.workflow_table_id, (period_license.annual_fee_due) as aggregate_charge
				FROM period_license
				INNER JOIN client_license ON period_license.client_license_id = client_license.client_license_id
				INNER JOIN license ON client_license.license_id = license.license_id
				WHERE license.license_id = CAST(lic_id AS INT)) LOOP

				INSERT INTO license_payment_header(license_payment_header_id,client_license_id,workflow_table_id,description) 
					VALUES(pay_header_id, my_lic.client_license_id, my_lic.workflow_table_id, 'ANNUAL FEE');
				COMMIT;
				
				INSERT INTO license_payment_line(license_payment_header_id, product_code, description, amount) 
					VALUES(pay_header_id, '0FFE42C843354755BE24AD5969EDCB0A', 'Annual Fee (KES)', my_lic.aggregate_charge);
				COMMIT;

				--SEND NOTIFICATIONS			
				INSERT INTO sys_emailed (sys_email_id, table_id, table_name, email_type) VALUES (72, my_lic.workflow_table_id, 'PERIOD_LICENSE', 50);
				COMMIT;	


			END LOOP;

			ELSIF lic_id = '158' OR lic_id = '159' OR lic_id = '160' THEN  --vsat

				FOR my_lic IN (SELECT period_license.client_license_id, client_license.workflow_table_id, (period_license.annual_fee_due) as aggregate_charge
					FROM period_license
					INNER JOIN client_license ON period_license.client_license_id = client_license.client_license_id
					INNER JOIN license ON client_license.license_id = license.license_id
					WHERE license.license_id = CAST(lic_id AS INT)) LOOP

					INSERT INTO license_payment_header(license_payment_header_id,client_license_id,workflow_table_id,description) 
						VALUES(pay_header_id, my_lic.client_license_id, my_lic.workflow_table_id, 'ANNUAL FEE');
					COMMIT;
					
					INSERT INTO license_payment_line(license_payment_header_id, product_code, description, amount) 
						VALUES(pay_header_id, '0FFE42C843354755BE24AD5969EDCB0A', 'Annual Fee (KES)', my_lic.aggregate_charge);
					COMMIT;

					--SEND NOTIFICATIONS			
					INSERT INTO sys_emailed (sys_email_id, table_id, table_name, email_type) VALUES (72, my_lic.workflow_table_id, 'PERIOD_LICENSE', 50);
					COMMIT;	


				END LOOP;

		END IF;
		

--FINALY THE APPROVALS
-- 			INSERT INTO approvals (workflow_phase_id, approval_group, table_name, table_id, org_entity_id, app_entity_id, escalation_days, escalation_hours, approval_level, approval_narrative, to_be_done)
-- 			SELECT workflow_phases.workflow_phase_id, appr_group, 'LICENSE_PAYMENT_HEADER', :NEW.table_id, :NEW.org_entity_id, entity_subscriptions.entity_id, 0, 3, 1, workflow_phases.phase_narrative, 'Confirm Payment - ' || workflow_phases.phase_narrative				
-- 				FROM workflow_phases				
-- 				INNER JOIN entity_subscriptions ON workflow_phases.approval_entity_id = entity_subscriptions.entity_type_id
-- 				WHERE workflow_phases.workflow_phase_id = nxt_phase_id;
-- 			COMMIT;	


	RETURN 'License Invoiced Successfully';

END;







CREATE OR REPLACE FUNCTION checkEntity(val IN varchar2) RETURN varchar2 IS
	PRAGMA AUTONOMOUS_TRANSACTION;
  
  cli_name	varchar(200);
  
	BEGIN	

	SELECT client_name INTO cli_name FROM client WHERE UPPER(client_name) LIKE UPPER('%'||val||'%') AND rownum = 1 ORDER BY client_name;

	IF(cli_name IS NULL)  THEN			
			RETURN 'This is a new client. please proceed';					
	ELSE
		RETURN 'Client with a similar name exists. (' || cli_name ||')';
	END IF;
  
	RETURN 'EOF';
  
END;
/


















CREATE OR REPLACE FUNCTION processClientInspection(cli_id IN varchar2, user_id IN varchar2, approval IN varchar2, filter_id IN varchar2) RETURN VARCHAR2 IS
	PRAGMA AUTONOMOUS_TRANSACTION;

	BEGIN

		--SELECT workflow_table_id, clc_id INTO tab_id, clc FROM client_license WHERE client_license_id = CAST(cli_lic_id AS INT);

		IF approval = 'SELECT' THEN
			RETURN 'NO SELECTION MADE';

		ELSIF approval = 'Add' THEN
    
			INSERT INTO client_inspection(client_id,sub_schedule_id,activity_type_id,created_by) VALUES(CAST(cli_id AS INT), CAST(filter_id AS INT),6, CAST(user_id AS INT));
			COMMIT;      
			RETURN 'Added '|| cli_id || ' to Schedule :' || filter_id ;

		ELSIF approval = 'Remove' THEN
    
			DELETE FROM client_inspection WHERE client_id = CAST(cli_id AS int) AND sub_schedule_id = CAST(filter_id AS int) AND activity_type_id = 6;
			COMMIT;      
			RETURN 'Removed '|| cli_id || ' From Schedule :' || filter_id ;

		ELSIF (approval = 'Complied' ) THEN			
			
			RETURN 'Client ' || approval;

		ELSIF (approval = 'Not Complied') THEN
			
			RETURN 'Client ' || approval;

		ELSE
			RETURN 'UNREACHABLE';
		END IF;

		
END;
/
