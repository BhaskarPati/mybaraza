---Project Database File
CREATE TABLE Price_List (
	price_list_id 					serial primary key,
	price_list_name					varchar (120),
	amount							real,
	details							text
);

CREATE TABLE Payments (
	payment_id 						serial primary key,
	service_id						serial primary key,
	price_list_id					integer references Price_List,
	payment_name					varchar (120),
	payment_date					date, 
	details							text
);

CREATE TABLE Services (

	service_id						serial primary key,
	price_list_id					integer references Price_List,
	payment_name					varchhar (120),
	service_name					varchar (120),
	service_date					date,
	details							text
);



CREATE VIEW vw_payments AS
	SELECT price_list.price_list_id, price_list.price_list_name, payments.payment_id, payments.payment_name, payments.payment_date, payments.details
	FROM payments
	INNER JOIN price_list ON payments.price_list_id = price_list.price_list_id;

CREATE VIEW vw_services AS
	SELECT price_list.price_list_id, price_list.price_list_name, services.service_id, services.service_name, services.service_date, services.details
	FROM services
	INNER JOIN price_list ON services.price_list_id = price_list.price_list_id;
