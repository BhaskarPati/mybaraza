---Project Database File
CREATE TABLE county (
	county_id				serial primary key,
	county_name				varchar(240),
	county_code				varchar(12),
	details					text
);

CREATE TABLE constituency (
	constituency_id			serial primary key,
	county_id				integer references county,
	constituency_name		varchar(240),
	constituency_code		varchar(12),
	details					text
);

CREATE TABLE wards (
	ward_id					serial primary key,
	constituency_id			integer references constituency,
	ward_name				varchar(240),
	ward_code				varchar(12),
	details					text
);

CREATE TABLE polling_stations (
	polling_station_id		serial primary key,
	ward_id					integer references wards,
	polling_station_name	varchar(240),
	polling_station_code	varchar(12),
	details					text
);

CREATE TABLE voters (
	voter_id				serial primary key,
	polling_station_id		integer references polling_stations,
	id_number				varchar(50),
	surname					varchar(50),
	other_names				varchar(50),
	electers_number			varchar(50),
	date_of_birth			date,
	gender					varchar(1),
	address					varchar(50),
	voter_status			integer,
	details					text
);

CREATE TABLE party (
	party_id				serial primary key,
	party_name				varchar(240),
	details					text
);

CREATE TABLE candidates (
	voter_id				integer references voters primary key,
	party_id				integer references party,
	election_year			integer,
	details					text
);

CREATE TABLE nominators (
	nominator_id			integer primary key,
	candidate_id			integer references candidates,
	voter_id				integer references voters,
	details					text
);

CREATE VIEW vw_constituency AS
	SELECT county.county_id, county.county_name, constituency.constituency_id, constituency.constituency_name, 
		constituency.constituency_code, constituency.details
	FROM constituency INNER JOIN county ON constituency.county_id = county.county_id;

CREATE VIEW vw_wards AS
	SELECT vw_constituency.county_id, vw_constituency.county_name, vw_constituency.constituency_id, vw_constituency.constituency_name, 
		vw_constituency.constituency_code, wards.ward_id, wards.ward_name, wards.ward_code, wards.details
	FROM wards INNER JOIN vw_constituency ON wards.constituency_id = vw_constituency.constituency_id;

CREATE VIEW vw_polling_stations AS
	SELECT vw_wards.county_id, vw_wards.county_name, vw_wards.constituency_id, vw_wards.constituency_name, 
		vw_wards.constituency_code, vw_wards.ward_id, vw_wards.ward_name, vw_wards.ward_code,
		polling_stations.polling_station_id, polling_stations.polling_station_name, polling_stations.polling_station_code, 
		polling_stations.details
	FROM polling_stations INNER JOIN vw_wards ON polling_stations.ward_id = vw_wards.ward_id;

CREATE VIEW vw_voters AS
	SELECT vw_polling_stations.county_id, vw_polling_stations.county_name, vw_polling_stations.constituency_id, 
		vw_polling_stations.constituency_name, vw_polling_stations.constituency_code, vw_polling_stations.ward_id, 
		vw_polling_stations.ward_name, vw_polling_stations.ward_code, vw_polling_stations.polling_station_id, 
		vw_polling_stations.polling_station_name, vw_polling_stations.polling_station_code, 
		voters.voter_id, voters.id_number, voters.surname, voters.other_names, voters.electers_number, 
		voters.date_of_birth, voters.gender, voters.address, voters.voter_status, voters.details
	FROM voters INNER JOIN vw_polling_stations ON voters.polling_station_id = vw_polling_stations.polling_station_id;

CREATE VIEW vw_candidates AS
	SELECT vw_voters.county_id, vw_voters.county_name, vw_voters.constituency_id, 
		vw_voters.constituency_name, vw_voters.constituency_code, vw_voters.ward_id, 
		vw_voters.ward_name, vw_voters.ward_code, vw_voters.polling_station_id, 
		vw_voters.polling_station_name, vw_voters.polling_station_code, 
		vw_voters.voter_id, vw_voters.id_number, vw_voters.surname, vw_voters.other_names, vw_voters.electers_number, 
		vw_voters.date_of_birth, vw_voters.gender, vw_voters.address, vw_voters.voter_status,
		party.party_id, party.party_name, candidates.election_year, candidates.details
	FROM candidates INNER JOIN party ON candidates.party_id = party.party_id
		INNER JOIN vw_voters ON candidates.voter_id = vw_voters.voter_id;

CREATE VIEW vw_nominators AS
	SELECT voters.voter_id, voters.surname, voters.other_names, nominators.nominator_id, nominators.candidate_id, 
		nominators.details
	FROM nominators INNER JOIN candidates ON nominators.candidate_id = candidates.voter_id
		INNER JOIN voters ON nominators.voter_id = voters.voter_id;


