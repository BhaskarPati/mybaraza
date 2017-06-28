

    CREATE TABLE quotationlogs (
        logsId serial PRIMARY KEY,
        email varchar(50),
        mobile_no varchar(50),
        rate_type varchar(50),
        rate_plan varchar(50),
        amount_1 real,
        status text,
        log_date timestamp default now() not null
    );
