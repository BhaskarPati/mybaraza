DROP VIEW vwmembers CASCADE;

ALTER TABLE members 
ADD	school				varchar(50),
ADD	level				varchar(25),
ADD	class				integer;

ALTER TABLE teammembers
DROP	school,
DROP	level,
DROP	class;

ALTER TABLE entity_types ADD start_view varchar(120);


CREATE VIEW vwmembers AS 
	SELECT countrys.countryid, countrys.countryname, members.memberid, members.firstname, members.lastname, members.familyname, 
		members.dateofbirth, members.occupation, members.nationality, members.nextofkeen, members.relationship, 
		members.contacts, members.active, members.details, members.placeofbirth, members.birthcertno, 
		members.certdate, members.registrationno, members.passportno, members.passportissuedate, members.passportexpirydate, 
		members.passportrefno, members.nationalid, members.idno, members.phoneno, 
		members.school, members.level, members.class,
		btrim((((members.firstname::text || ' '::text) || members.lastname::text) || ' '::text) || COALESCE(members.familyname, ''::character varying)::text) AS membername, 
		zones.zonename, teams.teamname
	FROM members INNER JOIN countrys ON members.nationality::bpchar = countrys.countryid
	LEFT JOIN teammembers ON teammembers.memberid = members.memberid
	LEFT JOIN teams ON teams.teamid = teammembers.teamid
	LEFT JOIN branches ON branches.branchid = teams.branchid
	LEFT JOIN zones ON zones.zoneid = branches.branchid;

CREATE VIEW vwteammembers AS 
	SELECT vwteams.branchid, vwteams.branchname, vwteams.categoryid, vwteams.categoryname, vwteams.gender, 
		vwteams.teamid, vwteams.teamname, vwteams.startdate, vwteams.enddate, 
		vwmembers.memberid, vwmembers.membername, vwmembers.school, vwmembers.level, vwmembers.class,
		teammembers.teammemberid, teammembers.coach, teammembers.captain, teammembers.details
	FROM teammembers JOIN vwmembers ON teammembers.memberid = vwmembers.memberid
		JOIN vwteams ON teammembers.teamid = vwteams.teamid;

CREATE VIEW vwplayers AS 
	SELECT vwteammembers.teammemberid, vwteammembers.memberid, vwteammembers.membername, vwteammembers.teamid, 
		vwteammembers.teamname, vwmatches.matchid, vwmatches.teama, vwmatches.teamb, vwmatches.dateofmatch, 
		vwmatches.starttime, vwmatches.played, vwmatches.fieldid, vwmatches.fieldname, vwmatches.poolid, 
		vwmatches.poolname, vwmatches.teamaname, vwmatches.teambname, 
		players.playerid, players.substitute, players.fairplay, players.bestplayer, players.intime, 
		players.outtime, players.details
	FROM players JOIN vwmatches ON players.matchid = vwmatches.matchid
		JOIN vwteammembers ON players.teammemberid = vwteammembers.teammemberid;

CREATE OR REPLACE VIEW vwinjurys AS 
	SELECT vwplayers.playerid, vwplayers.matchid, vwplayers.teammemberid, vwplayers.memberid, vwplayers.membername, 
		vwplayers.teamid, vwplayers.teamname, injurys.injuryid, injurys.injurytime, injurys.injutytype, 
		injurys.cause, injurys.comments, injurys.details
	FROM injurys JOIN vwplayers ON vwplayers.playerid = injurys.playerid;

CREATE OR REPLACE VIEW vwscores AS 
	SELECT vwplayers.playerid, vwplayers.matchid, vwplayers.teammemberid, vwplayers.memberid, vwplayers.membername, 
		vwplayers.teamid, vwplayers.teamname, scores.scoreid, scores.scoretime, scores.assisting, scores.scored, 
		scores.penalty, scores.details
	FROM scores JOIN vwplayers ON scores.playerid = vwplayers.playerid;

CREATE OR REPLACE VIEW vwoffences AS 
	SELECT vwplayers.playerid, vwplayers.matchid, vwplayers.teammemberid, vwplayers.memberid, vwplayers.membername, 
		vwplayers.teamid, vwplayers.teamname, offences.offenceid, offences.offencetime, offences.offencerule, 
		offences.card, offences.details
	FROM offences JOIN vwplayers ON offences.playerid = vwplayers.playerid;

CREATE VIEW vwtopscorers AS
	SELECT vwteammembers.memberid, vwteammembers.membername, vwteams.branchid, vwteams.branchname, 
		vwteams.teamname, vwteams.categoryid, (vwteams.categoryname ||':'|| vwteams.gender) as gender, 
		pools.seasonid, count(scores.scored) as scores
	FROM vwteams INNER JOIN vwteammembers ON vwteams.teamid = vwteammembers.teamid
	INNER JOIN players ON vwteammembers.teammemberid = players.teammemberid
	INNER JOIN scores ON players.playerid = scores.playerid
	INNER JOIN matches ON players.matchid = matches.matchid
	INNER JOIN pools ON matches.poolid = pools.poolid
	WHERE (scores.scored = true)
	GROUP BY vwteammembers.memberid, vwteammembers.membername, vwteams.branchid, vwteams.branchname, 
		vwteams.teamname, vwteams.categoryid, vwteams.categoryname, vwteams.gender, pools.seasonid;

CREATE VIEW vwcommetees AS
	SELECT commeteetypes.commeteetypeid, commeteetypes.commeteetypename, vwmembers.memberid, vwmembers.membername, 
		seasons.seasonid, seasons.startdate, seasons.enddate, commetees.commeteeid, 
		commetees.position, commetees.details
	FROM commetees INNER JOIN commeteetypes ON commetees.commeteetypeid = commeteetypes.commeteetypeid
		INNER JOIN vwmembers ON commetees.memberid = vwmembers.memberid
		INNER JOIN seasons ON commetees.seasonid = seasons.seasonid;

CREATE VIEW vwparticipants AS
	SELECT vwmembers.memberid, vwmembers.membername, participants.participantid, participants.meetingid, 
		participants.communityserviceid, participants.workshopid, participants.details
	FROM participants INNER JOIN vwmembers ON participants.memberid = vwmembers.memberid;

