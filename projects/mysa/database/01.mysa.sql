CREATE TABLE members (
	memberid			serial primary key,
	Firstname			varchar(25) not null,
	Lastname			varchar(25) not null,
	familyname			varchar(25),
	dateofbirth			date,
	occupation			varchar(50),
	nationality			varchar(2) references countrys,
	nextofkeen			varchar(50),
	relationship		varchar(75),
	contacts			varchar(50),
	active				boolean default false not null,
	placeofbirth		varchar(75),
	birthcertno			varchar(25),
	certdate			date,
	registrationno		varchar(25),
	passportno			varchar(25),
	passportissuedate	date,
	passportexpirydate	date,
	passportrefno		varchar(25),
	nationalid			varchar(15),
	idno				varchar(15),
	phoneno				varchar(50),
	gender 				varchar(1),
	school				varchar(50),
	level				varchar(25),
	class				integer,
	hasphoto			boolean default false not null,
	details				text
);
CREATE INDEX members_nationality ON members (nationality);

CREATE TABLE staff (
	staffid				serial primary key,
	staffname			varchar(50) not null,
	staffposition		varchar(100) not null,
	volunteer			boolean default false not null,
	mobile				varchar(50),
	email				varchar(120),
	mysastaffid 		varchar(100),
	employment_date 	date,
	contract_start 		date,
	contract_end 		date,
	date_of_birth 		date,
	department_name 	varchar(200),
	details				text
);

CREATE TABLE referees (
	refereeid			serial primary key,
	refereename			varchar(50) not null,
	qualifications		varchar(50) not null,
	fifastatus			varchar(50),
	volunteer			boolean default false not null,
	mobile				varchar(50),
	email				varchar(120),
	details				text
);

CREATE TABLE pointtypes (
	pointtypeid			serial primary key,
	pointtypename			varchar(50) not null,
	details				text
);

CREATE TABLE points (
	pointid				serial primary key,
	pointtypeid			integer references pointtypes,
	activity			varchar(50) not null,
	quantity			integer not null,
	points				real not null,
	details				text
);
CREATE INDEX points_pointtypeid ON points (pointtypeid);

CREATE TABLE zones (
	zoneid				serial primary key,
	zonename			varchar(50) not null,
	groupname			varchar(50) not null,
	regionname			varchar(50),
	details				text
);

CREATE TABLE zonestaff (
	zonestaffid			serial primary key,
	staffid				integer references staff,
	zoneid				integer references zones,
	active				boolean default true not null,
	startdate			date,
	endadte				date,
	details				text
);
CREATE INDEX zonestaff_zoneid ON zonestaff (zoneid);
CREATE INDEX zonestaff_staffid ON zonestaff (staffid);

CREATE TABLE branches (
	branchid			serial primary key,
	zoneid 				integer references Zones,
	branchname			varchar(50) not null,
	details				text
);
CREATE INDEX branches_zoneid ON branches (zoneid);

CREATE TABLE fields (
	fieldid				serial primary key,
	branchid			integer references branches,
	fieldname			varchar(50) not null,
	details				text
);
CREATE INDEX fields_branchid ON fields (branchid);

CREATE TABLE seasons (
	seasonid			char(4) primary key,
	startdate			date not null,
	enddate				date not null,
	active				boolean default false not null,
	details				text
);

CREATE TABLE commeteetypes (
	commeteetypeid		serial primary key,
	commeteetypename	varchar(50),
	details				text
);

CREATE TABLE commetees (
	commeteeid			serial primary key,
	commeteetypeid		integer references commeteetypes,
	memberid			integer references members,
	seasonid			char(4) references seasons,
	position			varchar(50),
	details				text
);
CREATE INDEX commetees_commeteetypeid ON commetees (commeteetypeid);
CREATE INDEX commetees_memberid ON commetees (memberid);
CREATE INDEX commetees_seasonid ON commetees (seasonid);

CREATE TABLE categories (
	categoryid			serial primary key,
	categoryname		varchar(25) not null,
	agelimit			integer not null,
	gender				varchar(1) not null,
	gametime			integer not null,
	resttime			integer not null,
	rounds				integer default 2 not null,
	roundmatches		integer default 9 not null,
	maxteams			integer default 21 not null,
	players				integer not null,
	rules				text,
	details				text
);

CREATE TABLE teams (
	teamid				serial primary key,
	categoryid			integer references categories,
	branchid			integer references branches,
	teamname			varchar(50) not null,
	startdate			date not null,
	enddate				date,
	active				boolean default false not null
	details				text
);
CREATE INDEX teams_categoryid ON teams (categoryid);
CREATE INDEX teams_branchid ON teams (branchid);

CREATE TABLE teammembers (
	teammemberid		serial primary key,
	teamid				integer references teams,
	memberid			integer references members,
	member_since 		date,
	coach				boolean default false not null,
	captain				boolean default false not null,
	details				text
);
CREATE INDEX teammembers_teamid ON teammembers (teamid);
CREATE INDEX teammembers_memberid ON teammembers (memberid);

CREATE TABLE pools (
	poolid				serial primary key,
	poolname			varchar(50) not null,
	seasonid			char(4) references seasons,
	categoryid			integer references categories,
	championship   		boolean default false not null,
	startdate			date,
	enddate				date,
	details				text
);
CREATE INDEX pools_seasonid ON pools (seasonid);
CREATE INDEX pools_categoryid ON pools (categoryid);

CREATE TABLE championships (
	championshipid		serial primary key,
	poolid				integer references pools,
	teamid 				integer references teams,
	gamepool			char(1) not null,
	details				text
);
CREATE INDEX championships_poolid ON championships (poolid);
CREATE INDEX championships_teamid ON championships (teamid);

CREATE TABLE matches (
	matchid				serial primary key,
	poolid				integer references pools,
	teamA				integer references teams,
	teamB				integer references teams,
	fieldid				integer references fields,
	firstreferee		integer references referees,
	secondreferee		integer references referees,
	thirdreferee		integer references referees,
	staffid				integer references staff,
	match_number		integer,
	dateofmatch			date not null,
	starttime			time not null,
	resttime			time not null,
	endtime				time not null,
	played				boolean default false not null,
	comments			text,
	details				text
);
CREATE INDEX matches_poolid ON matches (poolid);
CREATE INDEX matches_teama ON matches (teama);
CREATE INDEX matches_teamb ON matches (teamb);
CREATE INDEX matches_fieldid ON matches (fieldid);
CREATE INDEX matches_firstreferee ON matches (firstreferee);
CREATE INDEX matches_secondreferee ON matches (secondreferee);
CREATE INDEX matches_staffid ON matches (staffid);

CREATE TABLE match_referees (
	match_referee_id	serial primary key,
	matchid				integer references matches,
	memberid			integer references members,
	details				text
);
CREATE INDEX match_referees_matchid ON match_referees (matchid);
CREATE INDEX match_referees_memberid ON match_referees (memberid);

CREATE TABLE players (
	playerid			serial primary key,
	matchid				integer references matches,
	teammemberid 		integer references teammembers,
	substitute			boolean default false not null,
	fairplay			boolean default false not null,
	bestplayer			boolean default false not null,
	intime				time,
	outtime				time,
	details				text
);
CREATE INDEX players_matchid ON players (matchid);
CREATE INDEX players_teammemberid ON players (teammemberid);

CREATE TABLE injurys (
	injuryid			serial primary key,
	playerid			integer references players,
	injurytime			time not null,
	injutytype			text not null,
	cause				text not null,
	comments			text,
	details				text
);
CREATE INDEX injurys_playerid ON injurys (playerid);

CREATE TABLE scores (
	scoreid				serial primary key,
	playerid			integer references players,
	scoretime			time not null,
	assisting			boolean default false not null,
	scored				boolean default false not null,
	penalty				boolean default false not null,
	details				text
);
CREATE INDEX scores_playerid ON scores (playerid);

CREATE TABLE offences (
	offenceid			serial primary key,
	playerid			integer references players,
	offencetime			time not null,
	offencerule			text not null,
	card				char(1),
	details				text
);
CREATE INDEX offences_playerid ON offences (playerid);

CREATE TABLE meetings (
	meetingid			serial primary key,
	pointid				integer references points,
	dateofmeeting		date not null,
	meetingvenue		varchar(50) not null,
	starttime			time not null,
	endtime				time not null,
	meetingagenda		text not null,
	details				text
);
CREATE INDEX meetings_pointid ON meetings (pointid);

CREATE TABLE communityservices (
	communityserviceid	serial primary key,
	zoneid				integer references zones,
	pointid				integer references points,
	startdate			date not null,
	starttime			time not null,
	enddate				date not null,
	endtime				time not null,
	description			varchar(50) not null,
	details				text
);
CREATE INDEX communityservices_zoneid ON communityservices (zoneid);
CREATE INDEX communityservices_pointid ON communityservices (pointid);

CREATE TABLE workshops (
	workshopid			serial primary key,
	pointid				integer references points,
	startdate			date not null,
	starttime			time not null,
	enddate				date not null,
	endtime				time not null,
	workshopname		varchar(50) not null,
	description			varchar(50) not null,
	details				text
);
CREATE INDEX workshops_pointid ON workshops (pointid);

CREATE TABLE participants (
	participantid		serial primary key,
	memberid			integer references members,
	meetingid			integer references meetings,
	communityserviceid	integer references communityservices,
	workshopid			integer references workshops,
	details				text
);
CREATE INDEX participants_memberid ON participants (memberid);
CREATE INDEX participants_meetingid ON participants (meetingid);
CREATE INDEX participants_communityserviceid ON participants (communityserviceid);

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

CREATE VIEW vwpoints AS
	SELECT pointtypes.pointtypeid, pointtypes.pointtypename, points.pointid, points.activity, points.quantity, 
		points.points, points.details
	FROM points INNER JOIN pointtypes ON points.pointtypeid = pointtypes.pointtypeid;

CREATE VIEW vwzonestaff AS
	SELECT zones.zoneid, zones.zonename, staff.staffid, staff.staffname,
		zonestaff.zonestaffid, zonestaff.active, zonestaff.startdate, 
		zonestaff.endadte, zonestaff.details
	FROM zonestaff INNER JOIN zones ON zonestaff.zoneid = zones.zoneid
		INNER JOIN staff ON zonestaff.staffid = staff.staffid;

CREATE VIEW vwbranches AS
	SELECT zones.zoneid, zones.zonename, zones.groupname, zones.regionname,
		branches.branchid, branches.branchname, branches.details
	FROM branches INNER JOIN zones ON branches.zoneid = zones.zoneid;

CREATE VIEW vwfields AS
	SELECT branches.branchid, branches.branchname, fields.fieldid, fields.fieldname, fields.details
	FROM fields INNER JOIN branches ON fields.branchid = branches.branchid;

CREATE VIEW vwcommetees AS
	SELECT commeteetypes.commeteetypeid, commeteetypes.commeteetypename, vwmembers.memberid, vwmembers.membername, 
		seasons.seasonid, seasons.startdate, seasons.enddate, commetees.commeteeid, 
		commetees.position, commetees.details
	FROM commetees INNER JOIN commeteetypes ON commetees.commeteetypeid = commeteetypes.commeteetypeid
		INNER JOIN vwmembers ON commetees.memberid = vwmembers.memberid
		INNER JOIN seasons ON commetees.seasonid = seasons.seasonid;

CREATE VIEW vwteams AS
	SELECT branches.branchid, branches.branchname, categories.categoryid, categories.categoryname, categories.gender,
		teams.teamid, teams.teamname, teams.startdate, teams.enddate, teams.details
	FROM teams INNER JOIN branches ON teams.branchid = branches.branchid
		INNER JOIN categories ON teams.categoryid = categories.categoryid;

CREATE VIEW vwteammembers AS
	SELECT vwteams.branchid, vwteams.branchname, vwteams.categoryid, vwteams.categoryname, vwteams.gender,
		vwteams.teamid, vwteams.teamname, vwteams.startdate, vwteams.enddate,
		vwmembers.memberid, vwmembers.membername, 
		teammembers.teammemberid, teammembers.school, teammembers.level, teammembers.class, 
		teammembers.coach, teammembers.captain, teammembers.details
	FROM teammembers INNER JOIN vwmembers ON teammembers.memberid = vwmembers.memberid
		INNER JOIN teams ON teammembers.teamid = teams.teamid;

CREATE VIEW vwteammembers AS 
	SELECT vwteams.branchid, vwteams.branchname, vwteams.categoryid, vwteams.categoryname, vwteams.gender, 
		vwteams.teamid, vwteams.teamname, vwteams.startdate, vwteams.enddate, 
		vwmembers.memberid, vwmembers.membername, vwmembers.school, vwmembers.level, vwmembers.class,
		teammembers.teammemberid, teammembers.coach, teammembers.captain, teammembers.details
	FROM teammembers JOIN vwmembers ON teammembers.memberid = vwmembers.memberid
		JOIN vwteams ON teammembers.teamid = vwteams.teamid;

CREATE VIEW vwpools AS
	SELECT categories.categoryid, categories.categoryname, categories.gender, seasons.seasonid, 
		seasons.active, pools.poolid, pools.poolname, pools.championship,  pools.startdate, pools.enddate, pools.details
	FROM pools INNER JOIN categories ON pools.categoryid = categories.categoryid
		INNER JOIN seasons ON pools.seasonid = seasons.seasonid;

CREATE VIEW vwchampionships AS
	SELECT pools.poolid, pools.poolname, teams.teamid, teams.teamname, 
		championships.championshipid, championships.gamepool, championships.details
	FROM championships INNER JOIN pools ON championships.poolid = pools.poolid
		INNER JOIN teams ON championships.teamid = teams.teamid;

CREATE VIEW vwmatches AS
	SELECT fields.fieldid, fields.fieldname, pools.poolid, pools.poolname, 
		teamsa.teamname as teamaname, teamsb.teamname as teambname, 
		matches.matchid, matches.teama, matches.teamb, staff.staffid, staff.staffname,
		matches.dateofmatch, matches.starttime, matches.resttime, matches.endtime, matches.played, 
		matches.firstreferee, matches.secondreferee, matches.comments, matches.details
	FROM matches INNER JOIN fields ON matches.fieldid = fields.fieldid
		INNER JOIN staff ON matches.staffid = staff.staffid
		INNER JOIN pools ON matches.poolid = pools.poolid
		INNER JOIN teams as teamsa ON matches.teama = teamsa.teamid
		INNER JOIN teams as teamsb ON matches.teamb = teamsb.teamid;

CREATE VIEW vw_match_referees AS
	SELECT vwmatches.matchid, vwmatches.teama, vwmatches.teamb, vwmatches.dateofmatch, 
		vwmatches.starttime, vwmatches.played, vwmatches.fieldid, vwmatches.fieldname, vwmatches.poolid, 
		vwmatches.poolname, vwmatches.teamaname, vwmatches.teambname, 
		vwmembers.memberid, vwmembers.membername, 
		match_referees.match_referee_id, match_referees.details
	FROM match_referees INNER JOIN vwmatches ON match_referees.matchid = vwmatches.matchid
	INNER JOIN vwmembers ON match_referees.memberid = vwmembers.memberid;

CREATE OR REPLACE VIEW vwplayers AS 
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

CREATE VIEW vwcommunityservices AS
	SELECT zones.zoneid, zones.zonename, communityservices.communityserviceid, communityservices.startdate, 
		communityservices.starttime, communityservices.enddate, communityservices.endtime, 
		communityservices.description, communityservices.details, points.activity
	FROM communityservices INNER JOIN zones ON communityservices.zoneid = zones.zoneid
		INNER JOIN points ON communityservices.pointid = points.pointid;

CREATE VIEW vwmeetings AS
	SELECT meetings.meetingid, meetings.dateofmeeting, meetings.meetingvenue, meetings.starttime, meetings.endtime, 
		meetings.meetingagenda, meetings.details, points.activity
	FROM meetings INNER JOIN points ON meetings.pointid = points.pointid;

CREATE VIEW vwworkshops AS
	SELECT workshops.workshopid, workshops.startdate, workshops.starttime, workshops.enddate, workshops.endtime, 
		workshops.workshopname, workshops.description, workshops.details, points.activity
	FROM workshops INNER JOIN points ON workshops.pointid = points.pointid;

CREATE VIEW vwparticipants AS
	SELECT vwmembers.memberid, vwmembers.membername, participants.participantid, participants.meetingid, 
		participants.communityserviceid, participants.workshopid, participants.details
	FROM participants INNER JOIN vwmembers ON participants.memberid = vwmembers.memberid;

CREATE VIEW vwscorecount AS
	SELECT players.matchid, teammembers.teamid, count(scores.scoreid) as scorecount
	FROM scores INNER JOIN players ON scores.playerid = players.playerid
		INNER JOIN teammembers ON players.teammemberid = teammembers.teammemberid
	WHERE (scores.scored = true)
	GROUP BY players.matchid, teammembers.teamid;
 
CREATE VIEW vwleagues AS
	(SELECT pools.seasonid, pools.poolid, pools.poolname, matches.dateofmatch, matches.starttime, matches.endtime, 
		matches.matchid, matches.teama, matches.teamb, teams.teamname,
		COALESCE(sca.scorecount, 0) as goalfor, COALESCE(scb.scorecount, 0) as inscores, (COALESCE(sca.scorecount, 0) - COALESCE(scb.scorecount, 0)) as goaldif,
		(CASE WHEN COALESCE(sca.scorecount, 0) > COALESCE(scb.scorecount, 0) THEN 3
			WHEN COALESCE(sca.scorecount, 0) = COALESCE(scb.scorecount, 0) THEN 1
			ELSE 0 END) as points,
		(CASE WHEN COALESCE(sca.scorecount, 0) > COALESCE(scb.scorecount, 0) THEN 1 ELSE 0 END) as win,
		(CASE WHEN COALESCE(sca.scorecount, 0) = COALESCE(scb.scorecount, 0) THEN 1 ELSE 0 END) as draw,
		(CASE WHEN COALESCE(sca.scorecount, 0) < COALESCE(scb.scorecount, 0) THEN 1 ELSE 0 END) as loss
	FROM pools INNER JOIN matches ON pools.poolid = matches.poolid
		INNER JOIN teams ON matches.teama = teams.teamid
		LEFT JOIN vwscorecount as sca ON (matches.matchid = sca.matchid) AND (matches.teama = sca.teamid)
		LEFT JOIN vwscorecount as scb ON (matches.matchid = scb.matchid) AND (matches.teamb = scb.teamid)
	WHERE (matches.played = true))
	UNION
	(SELECT pools.seasonid, pools.poolid, pools.poolname, matches.dateofmatch, matches.starttime, matches.endtime, 
		matches.matchid, matches.teamb, matches.teama, teams.teamname,
		COALESCE(sca.scorecount, 0) as goalfor, COALESCE(scb.scorecount, 0) as inscores, (COALESCE(sca.scorecount, 0) - COALESCE(scb.scorecount, 0)) as goaldif,
		(CASE WHEN COALESCE(sca.scorecount, 0) > COALESCE(scb.scorecount, 0) THEN 3
			WHEN COALESCE(sca.scorecount, 0) = COALESCE(scb.scorecount, 0) THEN 1
			ELSE 0 END) as points,
		(CASE WHEN COALESCE(sca.scorecount, 0) > COALESCE(scb.scorecount, 0) THEN 1 ELSE 0 END) as win,
		(CASE WHEN COALESCE(sca.scorecount, 0) = COALESCE(scb.scorecount, 0) THEN 1 ELSE 0 END) as draw,
		(CASE WHEN COALESCE(sca.scorecount, 0) < COALESCE(scb.scorecount, 0) THEN 1 ELSE 0 END) as loss
	FROM pools INNER JOIN matches ON pools.poolid = matches.poolid
		INNER JOIN teams ON matches.teamb = teams.teamid
		LEFT JOIN vwscorecount as sca ON (matches.matchid = sca.matchid) AND (matches.teamb = sca.teamid)
		LEFT JOIN vwscorecount as scb ON (matches.matchid = scb.matchid) AND (matches.teama = scb.teamid)
	WHERE (matches.played = true));

CREATE VIEW vwleagueteams AS
	SELECT vwleagues.seasonid, vwleagues.poolid, vwleagues.poolname, vwleagues.teama, vwleagues.teamname, 
		count(vwleagues.matchid) as played, sum(vwleagues.win) as won, sum(vwleagues.draw) as drown, 
		sum(vwleagues.loss) as lost, sum(vwleagues.goalfor) as goalf, sum(vwleagues.inscores) as goala, sum(vwleagues.goaldif) as goald, sum(vwleagues.points) as points
	FROM vwleagues
	GROUP BY vwleagues.seasonid, vwleagues.poolid, vwleagues.poolname, vwleagues.teama, vwleagues.teamname;

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

CREATE OR REPLACE FUNCTION getPoints(char(4), int) RETURNS real AS $$
DECLARE
    reca RECORD;
	pnts real;
	tmppnts real;
BEGIN
	
	pnts := 0;
	
	SELECT seasonid, startdate, enddate INTO reca
	FROM seasons
	WHERE (seasonid = $1);
	
	SELECT sum(points.points / points.quantity) INTO tmppnts
	FROM meetings INNER JOIN participants ON meetings.meetingid = participants.meetingid
		INNER JOIN points ON meetings.pointid = points.pointid
	WHERE (participants.memberid = $2) 
		AND (dateofmeeting >= reca.startdate) AND (dateofmeeting <= reca.enddate);
	
	IF(tmppnts is not null) THEN
		pnts := pnts + tmppnts;
	END IF;
	
	RETURN pnts;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION getPoints2(char(4), int) RETURNS real AS $$
DECLARE
    reca RECORD;
	pnts real;
	tmppnts real;
BEGIN
	pnts := 0;
	
	SELECT seasonid, startdate, enddate INTO reca
	FROM seasons
	WHERE (seasonid = $1);
	
	SELECT sum(points.points / points.quantity) INTO tmppnts
	FROM communityservices INNER JOIN participants ON communityservices.communityserviceid = participants.communityserviceid
		INNER JOIN points ON communityservices.pointid = points.pointid
	WHERE (participants.memberid = $2) 
		AND (startdate >= reca.startdate) AND (enddate <= reca.enddate);
	
	IF(tmppnts is not null) THEN
		pnts := pnts + tmppnts;
	END IF;
	
	RETURN pnts;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION getPoints3(char(4), int) RETURNS real AS $$
DECLARE
    reca RECORD;
	pnts real;
	tmppnts real;
BEGIN
	
	pnts := 0;
	
	SELECT seasonid, startdate, enddate INTO reca
	FROM seasons
	WHERE (seasonid = $1);
	
	SELECT sum(points.points / points.quantity) INTO tmppnts
	FROM workshops INNER JOIN participants ON workshops.workshopid = participants.workshopid
		INNER JOIN points ON workshops.pointid = points.pointid
	WHERE (participants.memberid = $2) 
		AND (startdate >= reca.startdate) AND (enddate <= reca.enddate);
	
	IF(tmppnts is not null) THEN
		pnts := pnts + tmppnts;
	END IF;
	
	RETURN pnts;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION getTotalPoints(char(4), int) RETURNS real AS $$
DECLARE
    reca RECORD;
	pnts real;
	tmppnts real;
BEGIN
	
	pnts := 0;
	
	SELECT seasonid, startdate, enddate INTO reca
	FROM seasons
	WHERE (seasonid = $1);
	
	SELECT sum(points.points / points.quantity) INTO tmppnts
	FROM meetings INNER JOIN participants ON meetings.meetingid = participants.meetingid
		INNER JOIN points ON meetings.pointid = points.pointid
	WHERE (participants.memberid = $2) 
		AND (dateofmeeting >= reca.startdate) AND (dateofmeeting <= reca.enddate);
	
	IF(tmppnts is not null) THEN
		pnts := pnts + tmppnts;
	END IF;
	
	SELECT sum(points.points / points.quantity) INTO tmppnts
	FROM communityservices INNER JOIN participants ON communityservices.communityserviceid = participants.communityserviceid
		INNER JOIN points ON communityservices.pointid = points.pointid
	WHERE (participants.memberid = $2) 
		AND (startdate >= reca.startdate) AND (enddate <= reca.enddate);
	
	IF(tmppnts is not null) THEN
		pnts := pnts + tmppnts;
	END IF;
	
	SELECT sum(points.points / points.quantity) INTO tmppnts
	FROM workshops INNER JOIN participants ON workshops.workshopid = participants.workshopid
		INNER JOIN points ON workshops.pointid = points.pointid
	WHERE (participants.memberid = $2) 
		AND (startdate >= reca.startdate) AND (enddate <= reca.enddate);
	
	IF(tmppnts is not null) THEN
		pnts := pnts + tmppnts;
	END IF;
	
	RETURN pnts;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION getSportspoints(char(4), int) RETURNS real AS $$
DECLARE
	reca RECORD;
	pnts real;
	pnts1 real;
	pnts2 real;
	pnts3 real;
	pnts4 real;
	pnts5 real;
	tmppnts real;
BEGIN
	
	pnts := 0;

	SELECT seasonid, startdate, enddate INTO reca
	FROM seasons
	WHERE (seasonid = $1);

	pnts1 := 0;
	SELECT count(vwoffences.memberid) INTO pnts1 
	FROM vwoffences INNER JOIN matches ON vwoffences.matchid = matches.matchid
	WHERE (vwoffences.memberid = $2) AND (vwoffences.card = 'R')
		AND (matches.dateofmatch >= reca.startdate) AND (matches.dateofmatch <= reca.enddate);
	IF(tmppnts > 0) THEN
		pnts1 := -2.0;
	END IF;

	pnts2 := 0;
	SELECT count(vwoffences.memberid) INTO tmppnts 
	FROM vwoffences INNER JOIN matches ON vwoffences.matchid = matches.matchid
	WHERE (vwoffences.memberid = $2) AND vwoffences.card = 'Y'
		AND (matches.dateofmatch >= reca.startdate) AND (matches.dateofmatch <= reca.enddate);
	IF(tmppnts > 0) THEN
		pnts2 := -1.0;
	END IF;

	pnts3 := 0;
	SELECT count(vwplayers.memberid) INTO tmppnts
	FROM vwplayers INNER JOIN matches ON vwplayers.matchid = matches.matchid
	WHERE (vwplayers.memberid = $2) 
		AND (matches.dateofmatch >= reca.startdate) AND (matches.dateofmatch <= reca.enddate);
	IF(tmppnts is not null) THEN
		pnts3 := tmppnts/5;
	END IF;

	pnts4 := 0;
	SELECT count(vwplayers.memberid) INTO tmppnts 
	FROM vwteammembers INNER JOIN vwplayers ON vwteammembers.memberid = vwplayers.memberid
		INNER JOIN matches ON vwplayers.matchid = matches.matchid
	WHERE (vwteammembers.memberid = $2) AND (vwteammembers.captain = true)
		AND (matches.dateofmatch >= reca.startdate) AND (matches.dateofmatch <= reca.enddate);
	IF(tmppnts is not null) THEN
		pnts4 := tmppnts/5;
	END IF;

	pnts5 := 0;
	SELECT count(vwplayers.memberid) INTO tmppnts 
	FROM vwteammembers INNER JOIN vwplayers ON vwteammembers.memberid = vwplayers.memberid
		INNER JOIN matches ON vwplayers.matchid = matches.matchid
	WHERE (vwteammembers.memberid = $2) AND (vwteammembers.coach = true)
		AND (matches.dateofmatch >= reca.startdate) AND (matches.dateofmatch <= reca.enddate);
	IF(tmppnts is not null) THEN
		pnts5 := tmppnts/5;
	END IF;

	tmppnts = pnts1 + pnts2;	
	IF(tmppnts = 0) THEN
		pnts := pnts3 + 2 + pnts4 + pnts5;
	ELSE 
		pnts := pnts1 + pnts2 + pnts3 + pnts4 + pnts5;
	END IF;

	RETURN pnts;
END;
$$ LANGUAGE plpgsql;




