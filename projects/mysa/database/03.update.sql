
CREATE TABLE members_tmp (
  memberid serial primary key,
  firstname character varying(25) NOT NULL,
  lastname character varying(25) NOT NULL,
  familyname character varying(25),
  dateofbirth date,
  occupation character varying(50),
  nationality character varying(2),
  nextofkeen character varying(50),
  relationship character varying(75),
  contacts character varying(50),
  active boolean NOT NULL DEFAULT false,
  placeofbirth character varying(75),
  birthcertno character varying(25),
  certdate date,
  registrationno character varying(25),
  passportno character varying(25),
  passportissuedate date,
  passportexpirydate date,
  passportrefno character varying(25),
  nationalid character varying(15),
  idno character varying(15),
  phoneno character varying(50),
  details text,
  gender character varying(1),
  hasphoto boolean NOT NULL DEFAULT false,
  member_since date
);

INSERT INTO members_tmp (firstname, lastname, familyname, dateofbirth, occupation, nationality, nextofkeen, 
	relationship, contacts, active, placeofbirth, birthcertno, certdate, registrationno, passportno, 
	passportissuedate, passportexpirydate, passportrefno, nationalid, idno, 
	phoneno, details, gender, hasphoto, member_since)
SELECT firstname, lastname, familyname, dateofbirth, occupation, nationality, nextofkeen, 
	relationship, contacts, active, placeofbirth, birthcertno, certdate, registrationno, passportno, 
	passportissuedate, passportexpirydate, passportrefno, nationalid, idno, 
	phoneno, details, gender, hasphoto, member_since
FROM members
ORDER BY firstname, familyname;

DELETE FROM commetees;
DELETE FROM participants;
DELETE FROM scores;
DELETE FROM offences;
DELETE FROM players;
DELETE FROM teammembers;
DELETE FROM members;

DELETE FROM championships;
DELETE FROM matches;
DELETE FROM teams;

SELECT setval('commetees_commeteeid_seq', 1, false);
SELECT setval('participants_participantid_seq', 1, false);
SELECT setval('scores_scoreid_seq', 1, false);
SELECT setval('offences_offenceid_seq', 1, false);
SELECT setval('players_playerid_seq', 1, false);
SELECT setval('teammembers_teammemberid_seq', 1, false);
SELECT setval('members_memberid_seq', 1, false);

INSERT INTO members (firstname, lastname, familyname, dateofbirth, occupation, nationality, nextofkeen, 
	relationship, contacts, active, placeofbirth, birthcertno, certdate, registrationno, passportno, 
	passportissuedate, passportexpirydate, passportrefno, nationalid, idno, 
	phoneno, details, gender, hasphoto, member_since)
SELECT firstname, lastname, familyname, dateofbirth, occupation, nationality, nextofkeen, 
	relationship, contacts, active, placeofbirth, birthcertno, certdate, registrationno, passportno, 
	passportissuedate, passportexpirydate, passportrefno, nationalid, idno, 
	phoneno, details, gender, hasphoto, member_since
FROM members_tmp
ORDER BY firstname, familyname;

DROP TABLE members_tmp;


