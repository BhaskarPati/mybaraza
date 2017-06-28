---Project Database File

---TABLES

CREATE TABLE meeting_types (
	meeting_type_id			serial primary key,
	org_id					integer references orgs,
	meeting_type_name		varchar(320),
	details					text
);

CREATE TABLE meetings (
    meeting_id 				serial primary key,
	meeting_type_id 		integer references meeting_types,
	org_id					integer references orgs,
    meeting_name 			varchar(320),
    meeting_date 			date,
    meeting_venue 			varchar(320),
    meeting_agenda 			text,
	details					text
);

CREATE TABLE attendance (
    attendance_id 			serial primary key,
    meeting_id 				integer references meetings,
    entity_id 				integer references entitys,
	org_id					integer references orgs,
    attendance_status 		varchar(120),
	narrative				varchar(320)
);

---table imp_memberships not needed, used for migration demo

CREATE TABLE imp_memberships (
	imp_membership_id		serial primary key,
	Serial_No				varchar(240),
	Surname					varchar(240),
	Other_Names				varchar(240),
	Gender					varchar(240),
	Date_of_Birth			varchar(240),
	Postal_Code				varchar(240),
	Address					varchar(240),
	Town					varchar(240),
	Home_Telephone			varchar(240),
	Mobile					varchar(240),
	Email					varchar(240),
	Saved					varchar(240),
	Attendance				varchar(240),
	Year_of_Acceptance		varchar(240),
	Membership_by			varchar(240),
	Occupation				varchar(240),
	Place_of_Work			varchar(240),
	Office_Telephone		varchar(240),
	If_student_College		varchar(240),
	Course					varchar(240),
	Year					varchar(240),
	Marital_Status			varchar(240),
	Type_of_wedding			varchar(240),
	Year_of_marriage		varchar(240),
	Name_of_spouse			varchar(240),
	Tel_of_spouse			varchar(240),
	Number_of_children		varchar(240),
	Current_ministry		varchar(240),
	Desired_ministry		varchar(240),
	Area_of_Residence		varchar(240),
	Would_you_like_to		varchar(240),
	House_Group_Zone		varchar(240),
	Zone_Leader				varchar(240),
	Leadership_roles		varchar(240)
);


---VIEWS

CREATE VIEW vw_meetings AS
	SELECT meeting_types.meeting_type_id, meeting_types.meeting_type_name, 
		meetings.org_id, meetings.meeting_id, meetings.meeting_name, meetings.meeting_date, 
		meetings.meeting_venue, meetings.meeting_agenda, meetings.details
	FROM meetings INNER JOIN meeting_types ON meetings.meeting_type_id = meeting_types.meeting_type_id;

CREATE VIEW vw_attendance AS
	SELECT vw_meetings.meeting_type_id, vw_meetings.meeting_type_name, 
		vw_meetings.meeting_id, vw_meetings.meeting_name, vw_meetings.meeting_date, vw_meetings.meeting_venue,
		entitys.entity_id, entitys.entity_name, 
		attendance.org_id, attendance.attendance_id, attendance.attendance_status
	FROM attendance INNER JOIN vw_meetings ON vw_meetings.meeting_id = attendance.meeting_id
	INNER JOIN entitys ON entitys.entity_id = attendance.entity_id;

CREATE VIEW vw_ministries AS
 SELECT ministries.ministry_id,
    ministries.ministry_name,
    ministries.dept_id,
    departments.dept_name,
    ministries.org_id,
    orgs.org_name,
    ministries.details
  FROM ministries 
   INNER JOIN departments ON ministries.dept_id = departments.dept_id 
   INNER JOIN orgs ON  ministries.org_id = orgs.org_id ;

CREATE VIEW vw_ministry_memberships AS
  SELECT ministry_memberships.ministry_membership_id,
    ministry_memberships.ministry_id,
    ministries.ministry_name,
    ministry_memberships.entity_id,
    entitys.entity_name,
    ministry_memberships.rank,
    ministry_memberships.is_active
 FROM  ministry_memberships
  INNER JOIN entitys ON entitys.entity_id = ministry_memberships.entity_id
  INNER JOIN ministries ON ministries.ministry_id = ministry_memberships.ministry_id ;

---FUNCTIONS

CREATE OR REPLACE FUNCTION manage_attendance(character varying, character varying, character varying, character varying)
RETURNS character varying AS $$
DECLARE
	v_approval		integer;
	v_org_id		integer;
	v_response		varchar(255);

BEGIN
	v_response := '';
	
	v_org_id := cast($2 as int);
	v_approval := cast($3 as int);
	
	IF(v_approval = 1) THEN 
		INSERT INTO attendance(meeting_id,entity_id,org_id, attendance_status) VALUES( cast($4 as int), cast($1 as int), v_org_id, 'Present');
		v_response = 'Added to Meeting Successfully';
		
	ELSEIF(v_approval = 0) THEN
		DELETE FROM attendance WHERE attendance_id = cast($1 as int);
		v_response = 'Removed successfully';
		
	ELSEIF(v_approval = 2) THEN
		UPDATE attendance SET attendance_status = 'Absent' WHERE attendance_id = cast($1 as int);
		v_response = 'Marked Absent successfully';
		
	ELSEIF(v_approval = 3) THEN
		UPDATE attendance SET attendance_status = 'Present' WHERE attendance_id = cast($1 as int);
		v_response = 'Marked Present successfully';
	
	ELSEIF(v_approval = 4) THEN
		DELETE FROM meetings WHERE meeting_id = cast($1 as int);
		v_response = 'Meeting Removed successfully';

	ELSEIF(v_approval = 5) THEN
		UPDATE attendance SET attendance_status = 'AWA' WHERE attendance_id = cast($1 as int);
		v_response = 'Marked AWA successfully';


	
	END IF ;
	RETURN v_response ;
END;
$$ LANGUAGE plpgsql ;



---TRIGGERS (Trigger dropped)

CREATE OR REPLACE FUNCTION log_meetings_changes()
RETURNS trigger AS $BODY$
BEGIN
	INSERT INTO log_meetings (meeting_id, meeting_name, meeting_venue, meeting_agenda, meeting_date, changed_on)
	VALUES(OLD.meeting_id, OLD.meeting_name, OLD.meeting_venue, OLD.meeting_agenda, OLD.meeting_date, current_timestamp);
	RETURN NULL;
END;
$BODY$ LANGUAGE plpgsql;

