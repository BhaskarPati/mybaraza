INSERT INTO price_list (price_list_id, price_list_name, amount, details) VALUES (3, 'Main office table', 2000, NULL);
INSERT INTO price_list (price_list_id, price_list_name, amount, details) VALUES (4, 'Milk jar', 800, NULL);
INSERT INTO price_list (price_list_id, price_list_name, amount, details) VALUES (2, 'Office juice', 1000, NULL);
INSERT INTO price_list (price_list_id, price_list_name, amount, details) VALUES (5, 'Transit juice', 500, NULL);
INSERT INTO price_list (price_list_id, price_list_name, amount, details) VALUES (6, 'Office Pens', 2000, NULL);
INSERT INTO price_list (price_list_id, price_list_name, amount, details) VALUES (1, 'Shamba boy day', 3000, NULL);
INSERT INTO price_list (price_list_id, price_list_name, amount, details) VALUES (7, 'Shamba boy evening', 2000, NULL);
INSERT INTO price_list (price_list_id, price_list_name, amount, details) VALUES (8, 'Office entry', 2000, NULL);



SELECT pg_catalog.setval('price_list_price_list_id_seq', 8, true);