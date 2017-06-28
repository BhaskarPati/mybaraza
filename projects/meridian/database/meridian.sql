
ALTER TABLE accounts ADD is_bank_acc boolean default false;
ALTER TABLE accounts ADD bank_branch_id			integer references bank_branch;
ALTER TABLE accounts ADD bank_account_number	varchar(50);
	

CREATE SEQUENCE accounts_account_id_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 100000
  CACHE 1;
ALTER TABLE accounts_account_id_seq OWNER TO root;


CREATE TABLE partner(
	partner_id			serial primary key,
	entity_id			integer references entitys,

	sur_name			varchar(50),
	first_name			varchar(50),
	middle_name			varchar(50),

	type_of_business	varchar(50),
	year_started		integer, 		--the year this business was started
	details				text
	);

CREATE TABLE investor(
	investor_id			serial primary key,
	entity_id			integer references entitys,
	sur_name			varchar(50),
	first_name			varchar(50),
	middle_name			varchar(50),
	details				text
	);

CREATE TABLE investment_type (
	investment_type_id		serial primary key,
	investment_type_name		varchar(50),
	default_interest		real not null,		--commission interest
	details				text
	);
--initialization
INSERT INTO investment_type (investment_type_name) VALUES ('Default');


CREATE TABLE investment(
	investment_id		serial primary key,
	investor_id			integer references investor,
	investment_type_id	integer references investment_type,

	account_id			integer references accounts,

	principal			real not null check(principal > 0),
	credit_charge			real not null default 0,
	legal_fee			real not null default 0,
	valuation_fee			real not null default 0,
	trasfer_fee			real not null default 0,	
	investment_date			date not null default current_date,		--date of first maturity (should be within the targeted a/c period) .NB will work well if periods are closed b4 end of the month
	
	--interest			real not null check(interest > 0),
	monthly_repayment	real,		--emi/dividend? commission? 
	tenure_months		integer not null,	--n = number of months to maturity
	
	is_approved			boolean not null default false,	
	details				text
	);





CREATE TABLE borrower(
	borrower_id			serial primary key,
	entity_id			integer references entitys,

	sur_name			varchar(50),
	first_name			varchar(50),
	middle_name			varchar(50),

	employer_name		varchar(50),
	employment_date		date,
	position			varchar(50),
	employer_box		varchar(50),
	employer_town		varchar(50),
	employer_tel		varchar(50),	
	employer_fax		varchar(50),	

	net_salary		real,
	other_income	real,
	--total_income	real,

	house_rent		real,
	other_expenses	real,
	--total_expenses real,

	is_self_employed	boolean not null default false,
	business_name		varchar(50), 
	products_services	varchar(100),
	physical_address	varchar(100),
	office_size_sqft	real,
	business_rent		real,
	year_started		integer, 		--the year this business was started
	
	turnover_n_1		real,			--turnover for last year
	turnover_n_2		real,			--turnover for last year but one
	turnover_n_3		real,			--turnover for last year but two
	
	net_profit_n_1		real,			--net profit for last year
	net_profit_n_2		real,			--net profit for last year
	net_profit_n_3		real,			--net profit for last year
	details 			text
	);

--spouse or alternative contact
CREATE TABLE borrower_contact(
	borrower_contact_id	serial primary key,
	entity_id			integer references entitys,
	borrower_id			integer references borrower,
	employer_name		varchar(50),
	employment_date		date,
	position			varchar(50),
	employer_box		varchar(50),
	employer_town		varchar(50),
	employer_tel		varchar(50),	
	employer_fax		varchar(50),
	details				text
	);

CREATE TABLE referee(
	referee_id		serial primary key,
	entity_id		integer references entitys,
	borrower_id		integer references borrower,
	referee_name	varchar(50),
	mobile_tel_no	varchar(50),	
	office_tel_no	varchar(50),
	home_tel_no		varchar(50),

	details				text
	);

-- CREATE TABLE interest_type(
--       interest_type_id		serial primary key,
--       interest_type_name	varchar(50),
--       details			text
--       );
-- INSERT INTO interest_type(interest_type_id,interest_type_name) VALUES(1,'Fixed Line');
-- INSERT INTO interest_type(interest_type_id,interest_type_name) VALUES(2,'Reducing Balance');

--client products
CREATE TABLE loantypes (
	loantype_id			serial primary key,
	loantype_name			varchar(50),
	default_interest		real,
	is_reducing_balance		boolean default false,
	details				text
	);
--initialization
INSERT INTO loantypes (loantype_name, default_interest) VALUES ('Emergency Loan', 6);
INSERT INTO loantypes (loantype_name, default_interest) VALUES ('Education Loan', 12);
INSERT INTO loantypes (loantype_name, default_interest) VALUES ('Development Loan', 15);

CREATE TABLE loans (
	loan_id 				serial primary key,
	loantype_id			integer references loantypes,
	borrower_id			integer references borrower,
	principal			real not null check(principal > 0),
	credit_charge			real not null default 0,
	legal_fee			real not null default 0,
	valuation_fee			real not null default 0,
	trasfer_fee			real not null default 0,
	--total_principal		real,
	loandate			date not null default current_date,
	
	interest			real not null check(interest > 0),
	monthlyrepayment	real not null,		--emi 
	repaymentperiod		integer not null,	--n => number of monthly installments/repayments
	
	loanapproved		boolean not null default false,	
	narrative			text
);
--trigger to update transactions for contributions apart from the payroll 
--CREATE TRIGGER trans AFTER INSERT ON loans
--	FOR EACH ROW EXECUTE PROCEDURE insTransaction();

CREATE TABLE collateral(
	collateral_id	serial primary key,
	
	loan_id		integer references loans,
	isvehicle	boolean default true not null,
	isapproved	boolean default false not null,
	
	vehicle_owner	varchar(100),
	vehicle_regno	varchar(50),
	make			varchar(50),
	model			varchar(50),
	bodytype		varchar(50),
	color			varchar(50),
	engine_number	varchar(50),
	chassis_number	varchar(50),
	insurer			varchar(50),
	policy_no		varchar(50),
	insurance_value	real,
	valued_by		varchar(50),
	narrative 		text	
	);

CREATE TABLE payment_mode(
	payment_mode_id		serial primary key,
	payment_mode_name	varchar(20),
	processing_fee		real,					--Cheques may be charged 150 on top
	details 		text
	);
INSERT INTO payment_mode (payment_mode_id, payment_mode_name, processing_fee) VALUES(1,'CASH', 0);
INSERT INTO payment_mode (payment_mode_id, payment_mode_name, processing_fee) VALUES(2,'CHEQUE', 0);
INSERT INTO payment_mode (payment_mode_id, payment_mode_name, processing_fee) VALUES(3,'M-PESA', 0);
INSERT INTO payment_mode (payment_mode_id, payment_mode_name, processing_fee) VALUES(4,'ZAP', 0);

--one(loan) to many(reinbursements) accomodated....
--all payments (wether in full or in installments) given to loan applicant...aka reinbursement
CREATE TABLE loan_reinbursment (
	loan_reinbursment_id		serial primary key,
	loan_id					integer references loans,
	--memberid				integer references members,
	--witnessid				integer references members,
	
	amount_reinbursed		real not null check(amount_reinbursed > 0),

	payment_mode_id			integer references payment_mode,
	documentnumber			varchar(20),	--cheque number for now
	paymentnarrative		text,
	bank_branch_id			integer references bank_branch,

	created					date default current_date not null,
	createdby 				integer references entitys,
	details					text, 			--entered by creator

	updated					date,
	--updatedby				integer references users,
	narrative				text			--entered by updator

	);
--CREATE INDEX loanreinbursment_loanid ON loanreinbursment(loanid);
--CREATE INDEX loanreinbursment_paymentmodeid ON loanreinbursment(paymentmodeid);




CREATE TABLE loan_monthly (
	loanmonth_id 			serial primary key,
	loan_id				integer references loans,
	period_id			integer references periods,
	interest_amount			real not null,
	repayment			real not null,
	interest_paid			real default 0 not null,
	penalty				real default 0 not null,
	details				text,
	UNIQUE (loan_id, period_id)
	);


----====AFTER THE DISASTER
CREATE TABLE cheque_status(
  cheque_status_id	serial primary key,
  cheque_status_name	varchar(50),
  details		text
  );
INSERT INTO cheque_status(cheque_status_id, cheque_status_name) VALUES(1,'PENDING');
INSERT INTO cheque_status(cheque_status_id, cheque_status_name) VALUES(2,'CLEARED');
INSERT INTO cheque_status(cheque_status_id, cheque_status_name) VALUES(3,'DISHONOURED');


CREATE TABLE tax_category(
    tax_category_id	serial primary key,
    tax_category_name	varchar(50),
    details		text
    );
INSERT INTO tax_category(tax_category_name) VALUES('DEFAULT');

CREATE TABLE tax(
    tax_id		serial primary key,
    tax_category_id	integer references tax_category,
    tax_name		varchar(50),
    tax_rate		real not null,		--percentage
    details		text
    );
INSERT INTO tax(tax_category_id,tax_name,tax_rate) VALUES(1,'Withholding Tax',5.0);

CREATE TABLE fee_type(
  fee_type_id	serial primary key,
  fee_type_name	varchar(20),
  details	text
  );
INSERT INTO fee_type (fee_type_name) VALUES('Fixed Charge (Kshs)');
INSERT INTO fee_type (fee_type_name) VALUES('Percentage (%)');


CREATE TABLE fees(
  fee_id	serial primary key,	
  fee_type_id	integer references fee_type,
  fee_code	varchar(10),
  fee_name	varchar(50),
  fee_value	real not null default 0,
  minimum_charge	real default 0,
  details	text  
  );
INSERT INTO fees(fee_id,fee_name,fee_type_id,fee_value) VALUES(1,'PROCESSING FEE',1,500);
--INSERT INTO fees(fee_id,fee_name,fee_type_id,fee_value) VALUES(1,'PROCESSING FEE',1,500);

--we need to track all deductions/reductions (if any) for each investment separately
CREATE TABLE deduction(
	deduction_id		serial primary key,	
	investment_id			integer references investment,
	deduction_amount		real not null default 0,
	effective_date			date,
      
	--cheque details

	details				text
      );


--monthly maturity of investments
CREATE TABLE investment_maturity(
    investment_maturity_id		serial primary key,
    investment_id			integer references investment,
    period_id				integer references periods,

    mature_amount			real not null,		--remaining principal
    interest_amount			real not null,		--commision payable
	
    details				text
    );


CREATE TABLE commission_payment(
    commission_payment_id		serial primary key,
    investment_maturity_id		integer references investment_maturity,
    
    cheque_number			varchar(50),
    cheque_amount			real,
    cheque_date				date,    
    
    is_confirmed			boolean default false,
    is_paid				boolean default false,
    details				text	
    );



--recovered
CREATE TABLE fiscal_years (
	fiscal_year_id			varchar(9) primary key,
	fiscal_year_start		date not null,
	fiscal_year_end			date not null,
	year_opened				boolean default true not null,
	year_closed				boolean default false not null,
	details					text
);


CREATE TABLE periods
(
	period_id 		serial primary key,
	fiscal_year_id		varchar(9) references fiscal_years,
	period_opened		boolean not null default false,
	period_closed		boolean not null default false,
	period_start		date NOT NULL,
	period_end 		date NOT NULL,
	dividend_rate 		real NOT NULL DEFAULT 0,
	close_month 		boolean NOT NULL DEFAULT false,
	is_active 		boolean NOT NULL DEFAULT false,
	details text,
	unique(period_start,period_end)
);
CREATE INDEX periods_fiscal_year_id ON periods (fiscal_year_id);



CREATE TABLE journals (
	journal_id		serial primary key,
	period_id		integer not null references periods,
  
	investor_id		integer references investor,
	borrower_id		integer references borrower,

	journal_date		date not null,
	posted			boolean not null default false,
	narrative		varchar(240),
	details			text
	);	
CREATE INDEX journals_period_id ON journals (period_id);


CREATE TABLE gls (
	gl_id				serial primary key,
	journal_id			integer not null references journals,
	account_id			integer not null references accounts,
	
	debit				real not null default 0,
	credit				real not null default 0,

	action_date		date default current_date;

	gl_narrative			varchar(240)
	);
CREATE INDEX gls_journal_id ON gls (journal_id);
CREATE INDEX gls_account_id ON gls (account_id);

CREATE TABLE bank (
    bank_id 		serial NOT NULL,
    bank_code 		char(3),
    banka_bbrev 	varchar(10),
    bank_name 		varchar(30),
    details 		text
    );

CREATE TABLE bank_branch(
    bank_branch_id 	serial primary key,
    bank_id		integer references bank,
    bank_branch_name	varchar(50),
    details 		text
    );
  
CREATE TABLE repayment_table(
  repayment_table_id 	serial primary key,
  loan_id 		integer references loans,

  loan_period 		integer,
  loan_period_balance 	real NOT NULL,
  interest_component 	real NOT NULL DEFAULT 0,

  cheque_name 		character varying(50),
  cheque_number 	character varying(50),
  cheque_date 		date,
  cheque_amount 	real,
  bank_branch_id 	integer references bank_branch,
  penalty 		real NOT NULL DEFAULT 0,
  is_confirmed 		boolean DEFAULT false,
  is_paid 		boolean DEFAULT false,
  is_dishonoured	boolean default false,
  cheque_status_id	integer references cheque_status,

  details 		text,
  principal_component 	real NOT NULL DEFAULT 0,
  emi 			real NOT NULL DEFAULT 0,
  branch_name 		character varying(50),
  bank_name 		character varying(50),

  banking_slip		text,

  is_defaulted		boolean default false,		--when true... insert into defaulters' table

  details		text
  );




CREATE TABLE defaulter(
    defaulter_id	serial primary key,
    entity_id		integer references entitys,
    repayment_table_id	integer references repayment_table,	--specific repayment where default is/began
    demand_letter_sent	boolean default false,
    details		text
    );



--phases in an auction
CREATE TABLE phase(
    phase_id		serial primary key,
    phase_name		varchar(20),
    phase_level		integer,
    default_charge	real not null default 0,

    details		text
    );


CREATE TABLE auction(
    auction_id	serial primary key,
    defaulter_id	integer references defaulter,
    
    --we need auctioneer stuff
  
    is_complete		boolean default false,
    details 		text
    );

DROP TABLE auction_phase;
CREATE TABLE auction_phase(
    auction_phase_id	serial primary key,
    auction_id		integer references auction,
    phase_id		integer references phase,
  
    is_complete		boolean default false,
    details 		text
    );


CREATE TABLE investigation(
    investigation_id	serial primary key,
    defaulter_id	integer references defaulter,
     
    is_complete		boolean default false,
    details 		text
    );


CREATE TABLE civil_action(
    civil_action_id	serial primary key,
    investigation_id	integer references investigation,
    
    is_complete		boolean default false,
    details 		text
    );