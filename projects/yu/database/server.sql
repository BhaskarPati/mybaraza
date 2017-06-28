CREATE TABLE yuCash_Customers (
	Client_No			varchar(120) primary key,
	Asset_No			varchar(120),
	Client_Name			varchar(120),
	Owing				real
);

CREATE TABLE yuCash_Cust_Payment (
	transaction_id		int NOT NULL DEFAULT 0 primary key,
	client_id			varchar(32) NOT NULL DEFAULT '',
	asset_id			varchar(32) NOT NULL DEFAULT '',
	client_name			varchar(32) NOT NULL DEFAULT '',
	phone_number		varchar(32) NOT NULL DEFAULT '',
	payment_date		datetime NOT NULL DEFAULT '1753.01.01',
	amount				decimal(38, 20) NOT NULL DEFAULT ((0.0)),
	details				varchar(250) NOT NULL DEFAULT (''),
	track_id			int IDENTITY(1,1) NOT NULL,
	taken				tinyint NOT NULL DEFAULT ((0))
);


INSERT INTO yuCash_Customers (Client_No, Asset_No, Client_Name, Owing) VALUES ('BR/CST/MSA/CGW/127', 'BRMSA76', 'WILSON IRUNGU', '6000.00');
INSERT INTO yuCash_Customers (Client_No, Asset_No, Client_Name, Owing) VALUES ('BR/CST/MSA/CGW/128', 'BRMSA994', 'FR DOLAN GABRIEL', '20000.00');
INSERT INTO yuCash_Customers (Client_No, Asset_No, Client_Name, Owing) VALUES ('BR/CST/MSA/CGW/129', 'BRMSA993', 'FR NICHOLAS HENNITY', '20000.00');
INSERT INTO yuCash_Customers (Client_No, Asset_No, Client_Name, Owing) VALUES ('BR/CST/MSA/CGW/130', 'BRMSA986', 'WAMBAA EMMA MUTHONI', '20000.00');
INSERT INTO yuCash_Customers (Client_No, Asset_No, Client_Name, Owing) VALUES ('BR/CST/MSA/CGW/131', 'BRCGW1', 'REBECCA WANJIRU MWICIGI', '20000.00');
INSERT INTO yuCash_Customers (Client_No, Asset_No, Client_Name, Owing) VALUES ('BR/CST/MSA/CGW/132', 'BRMSA1356', 'SAMSON ODHIAMBO OKOTH', '3000.00');
INSERT INTO yuCash_Customers (Client_No, Asset_No, Client_Name, Owing) VALUES ('BR/CST/MSA/CGW/133', 'BRMSA1356', 'SAMSON WERE', '3000.00');


