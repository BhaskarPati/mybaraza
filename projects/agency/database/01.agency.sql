CREATE TABLE client_requests (
	client_request_id		serial primary key,
	entity_id				integer references entitys,
	org_id					integer references orgs,
	request_date			timestamp default now(),
	active					boolean default false,
	finalised				boolean default false,
	passanger				varchar(240),
	travel_date				date,
	return_date				date,
	origin					varchar(50),
	Destination				varchar(50),
	budget					real,
	flight					boolean default true,
	return					boolean default true,
	hotel					boolean default true,
	tour					boolean default true,
	in_transfer				boolean default false,
	out_transfer			boolean default false,
	details					text
);
CREATE INDEX client_requests_entity_id ON client_requests (entity_id);
CREATE INDEX client_requests_org_id ON client_requests (org_id);

CREATE TABLE request_responses (
	request_response_id		serial primary key,
	client_request_id		integer references client_requests,
	entity_id				integer references entitys,
	org_id					integer references orgs,
	sent_date				timestamp default now(),
	completed				boolean default false,
	complete_date			timestamp,
	amount					real,
	commision				real,
	service_fee				real,
	details					text
);
CREATE INDEX request_responses_client_request_id ON request_responses (client_request_id);
CREATE INDEX request_responses_entity_id ON request_responses (entity_id);
CREATE INDEX request_responses_org_id ON request_responses (org_id);

CREATE TABLE galileo_queues (
	galileo_queue_name		varchar(3) primary key,
	org_id					integer references orgs,
	galileo_queue_value		integer,
	narrative				varchar(240)
);
CREATE INDEX galileo_queues_org_id ON galileo_queues (org_id);

CREATE VIEW vw_client_requests AS
	SELECT entitys.entity_id as client_id, entitys.entity_name as client_name, 
		client_requests.org_id, client_requests.client_request_id, 
		client_requests.request_date, client_requests.passanger, client_requests.travel_date, client_requests.return_date, 
		client_requests.origin, client_requests.destination, client_requests.flight, client_requests.return,
		client_requests.hotel, client_requests.tour, client_requests.in_transfer, client_requests.out_transfer, 
		client_requests.active, client_requests.finalised, client_requests.details
	FROM client_requests INNER JOIN entitys ON client_requests.entity_id = entitys.entity_id;

CREATE VIEW vw_request_responses AS
	SELECT vw_client_requests.client_id, vw_client_requests.client_name, vw_client_requests.client_request_id, 
		vw_client_requests.request_date, vw_client_requests.passanger, vw_client_requests.travel_date, vw_client_requests.return_date, 
		vw_client_requests.origin, vw_client_requests.destination, vw_client_requests.flight, vw_client_requests.return,
		vw_client_requests.hotel, vw_client_requests.tour, vw_client_requests.in_transfer, vw_client_requests.out_transfer, 
		vw_client_requests.active, vw_client_requests.finalised, vw_client_requests.details as request_details,
		entitys.entity_id as consultant_id, entitys.entity_name as consultant_name, 
		request_responses.org_id, request_responses.request_response_id, request_responses.sent_date, 
		request_responses.completed, request_responses.complete_date, request_responses.amount, 
		request_responses.commision, request_responses.service_fee, request_responses.details
	FROM request_responses INNER JOIN vw_client_requests ON request_responses.client_request_id = vw_client_requests.client_request_id
	INNER JOIN entitys ON request_responses.entity_id = entitys.entity_id;

CREATE OR REPLACE FUNCTION ins_galileo_queues(varchar(32), int) RETURNS varchar(120) AS $$
DECLARE
	queue_name varchar(3);
BEGIN
	SELECT galileo_queue_name INTO queue_name FROM galileo_queues WHERE galileo_queue_name = $1;

	IF (queue_name is null) THEN
		INSERT INTO galileo_queues (galileo_queue_name, galileo_queue_value) VALUES ($1, $2);
	ELSE
		UPDATE galileo_queues SET galileo_queue_value = $2  WHERE galileo_queue_name = $1;
	
	END IF;

	return 'Added Galileo Queues';
END;
$$ LANGUAGE plpgsql;



