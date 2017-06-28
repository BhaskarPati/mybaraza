
DROP VIEW vwmatches CASCADE;
DROP VIEW vwmatches2;

ALTER TABLE matches
DROP	firstreferee,
DROP	secondreferee,
DROP	thirdreferee;

CREATE TABLE match_referees (
	match_referee_id	serial primary key,
	matchid				integer references matches,
	memberid			integer references members,
	details				text
);
CREATE INDEX match_referees_matchid ON match_referees (matchid);
CREATE INDEX match_referees_memberid ON match_referees (memberid);

CREATE VIEW vwmatches AS
	SELECT fields.fieldid, fields.fieldname, pools.poolid, pools.poolname, pools.seasonid, 
		teamsa.branchid AS branchaid, teamsa.teamname as teamaname,
		teamsb.branchid AS branchbid, teamsb.teamname as teambname, 
		matches.matchid, matches.teama, matches.teamb, staff.staffid, staff.staffname,
		matches.dateofmatch, matches.starttime, matches.resttime, matches.endtime, matches.played, 
		matches.comments, matches.details
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

