
NOTICE:  drop cascades to 8 other objects
DETAIL:  drop cascades to view vwcommetees
drop cascades to view vwteammembers
drop cascades to view vwplayers
drop cascades to view vwinjurys
drop cascades to view vwoffences
drop cascades to view vwscores
drop cascades to view vwtopscorers
drop cascades to view vwparticipants
Query returned successfully with no result in 54 ms.


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


