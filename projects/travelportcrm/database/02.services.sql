
CREATE TABLE AssetTypes (
	AssetTypeID				serial primary key,
	AssetTypeName			varchar(50) not null,
	cost					real,
	Details		 			text
);

CREATE TABLE AssetSubTypes (
	AssetSubTypeID			serial primary key,
	AssetTypeID				integer references AssetTypes,
	AssetSubTypeName		varchar(50) not null,
	ClientCost				float,
	segments				float,
	Details		 			text
);
CREATE INDEX AssetSubTypes_AssetTypeID ON AssetSubTypes (AssetTypeID);

CREATE TABLE ERF (
	ERFID					serial primary key,
	ProblemLogID			integer references ProblemLog,
	AssetSubTypeID			integer references AssetSubTypes,
	entity_id				integer references entitys,
	Replacement				boolean not null default false,
	Quantity				integer,
	Details					text
);
CREATE INDEX ERF_ProblemLogID ON ERF (ProblemLogID);
CREATE INDEX ERF_AssetSubTypeID ON ERF (AssetSubTypeID);
CREATE INDEX ERF_entity_id ON ERF (entity_id);

CREATE TABLE Assets (
	AssetID	 				serial primary key,
	AssetSubTypeID			integer references AssetSubTypes,
	AssetSN					varchar(32),
	IsInStore				boolean not null default false,
	Purchasedate 			date not null default current_date,
	IsOnLease				boolean not null default false,
	PurchaseCost			float not null default 0,
	MonthlyCost				float not null default 0,
	MonthlyMaintenance		float not null default 0,
	WarrantyPeriod			integer not null default 6,
	SingularItem			boolean not null default true,
	lost					boolean not null default false,
	lostdate				date,
	sold					boolean not null default false,
	Saledate				date,
	saleamount				real,
	soldto					varchar(120),
	LastStore				varchar(120),
	Condition 				varchar(240)
);
CREATE INDEX Assets_AssetSubTypeID ON Assets (AssetSubTypeID);

CREATE TABLE ClientAssets (
	ClientAssetID 			serial primary key,
	ClientID				integer references Clients,
	AssetID					integer references Assets,
	ProblemLogID			integer references ProblemLog,
	IsIssued				boolean not null default true,
	dateIssued 				date not null default current_date,
	IsRetrived				boolean default false not null,
	units					integer default 1 not null,
	crmrefno				varchar(50),
	dnoteno					varchar(50),
	rcrmrefno				varchar(50),
	rdnoteno				varchar(50),
	dateRetrived			date,
	Narrative 				varchar(240),
	dateadded				date default current_date,
	datechanged				date
);
CREATE INDEX ClientAssets_ClientID ON ClientAssets (ClientID);
CREATE INDEX ClientAssets_AssetID ON ClientAssets (AssetID);
CREATE INDEX ClientAssets_ProblemLogID ON ClientAssets (ProblemLogID);

CREATE TABLE PCConfiguration (
	PCConfigurationID		serial primary key,
	ClientID				integer references Clients,
	CPUSN					varchar(32),
	FPNET					boolean not null,
	FPConfig				varchar(32),
	ISP						varchar(32),
	Orderdate				date,
	ConfigNumber			varchar(32),
	IPAddress				varchar(32),
	SubnetMask				varchar(32),
	GIClientID				varchar(32),
	IWSGTID					varchar(32),
	Printer1GTID			varchar(32),
	Printer2GTID			varchar(32),
	Details					text
);
CREATE INDEX PCConfiguration_ClientID ON PCConfiguration (ClientID);

CREATE TABLE Segments (
	SegmentID				serial primary key,
	YearMonth 				varchar(4),
   	City 					varchar(3),
   	ISO 					varchar(2),
   	PCC						varchar(4),
   	Agency					varchar(75),
   	NASegs					integer,
	NPSegs					integer,
	NFASegs					integer,
	NBBSegs					integer,
	NRSegs					integer,
	BCT						integer,
	AOTSegs					integer,
	PTSegs					integer,
	Downloaddate			date not null default current_date,
	IsUploaded				boolean not null default false
);

CREATE TABLE ConsultantSegments (
	ConsultantSegmentID		serial primary key,
	YearMonth 				varchar(4),
   	City 					varchar(3),
   	PCC						varchar(4),
	SON						varchar(4),
	prd1					integer,
	prd2					integer,
	prd3					integer,
	Downloaddate			date not null default current_date,
	IsUploaded				boolean not null default false
);

CREATE TABLE MIDTSegments (
	MIDTSegmentID			serial primary key,
	YearMonth 				real,
   	CRS 					varchar(12),
   	PCC						varchar(25),
	Agency					varchar(120),	
	IATANo					varchar(50),
	prd						real,
	Downloaddate			date not null default current_date,
	IsUploaded				boolean not null default false
);

CREATE TABLE TKPSegments (
	TKPSegmentID			serial primary key,
	crs						varchar(2),
	RYear					varchar(4),
	RMonth 					varchar(2),
	country					varchar(2),
   	PCC						varchar(4),
	tcode					varchar(2),
	prd1					real,
	prd2					real,
	prd3					real,
	prd4					real,
	prd5					real,
	prd6					real,
	prd7					real,
	prd8					real,
	prd9					real,
	prd10					real,
	prd11					real,
	prd12					real,
	prd13					real,
	Downloaddate			date not null default current_date,
	IsUploaded				boolean not null default false
);

CREATE TABLE Periods (
	PeriodID				serial primary key,
	AccountPeriod			varchar(12) not null,
	Startdate				date not null,
	gkmonthyear				varchar(4),
	NASRate					float,
	CANCRates				float,
	TPRate					float,
	TARate					float,
	IncentiveRate			float default 0.4 not null,
	CompetitionCost			float default 3.0 not null,
	BudgetRate				float default 5 not null,
	IsUploaded				boolean not null default false,
	IsPicked				boolean not null default false,
	Details					text
);

CREATE TABLE PeriodAssetCosts (
	PeriodAssetCostID		serial primary key,
	AssetSubTypeID			integer references AssetSubTypes,
	PeriodID				integer references periods,
	ClientCost				float,
	segments				float,
	Narrative				varchar(120)
);
CREATE INDEX PeriodAssetCosts_AssetSubTypeID ON PeriodAssetCosts (AssetSubTypeID);
CREATE INDEX PeriodAssetCosts_PeriodID ON PeriodAssetCosts (PeriodID);

CREATE TABLE AssetSubCosts (
	AssetSubCostID			serial primary key,
	AssetSubTypeID			integer references AssetSubTypes,
	ClientCost				float,
	segments				float,
	narrative				varchar(240)
);
CREATE INDEX AssetSubCosts_AssetSubTypeID ON AssetSubCosts (AssetSubTypeID);

CREATE TABLE Transactions (
	TransactionID			serial primary key,
	ClientID				integer references Clients,
	PeriodID				integer references periods,
	entity_id				integer references entitys,
	PCC						varchar(4),
	GalileoCost				float,
   	NASegs					integer,
	NPSegs					integer,
	NFASegs					integer,
	NBBSegs					integer,
	NRSegs					integer,
	BCT						integer,
	AOTSegs					integer,
	PTSegs					integer,
	eticket					integer,
	pticket					integer,
	Productivity			integer,
	Narrative				varchar(240),
	UNIQUE(ClientID, PeriodID) 
);
CREATE INDEX Transactions_ClientID ON Transactions (ClientID);
CREATE INDEX Transactions_PeriodID ON Transactions (PeriodID);
CREATE INDEX Transactions_entity_id ON Transactions (entity_id);

CREATE TABLE ConsultantTransactions (
	ConsultantTransactionID	serial primary key,
    ClientID				integer references Clients,
	PeriodID				integer references periods,
   	PCC						varchar(4),	
	SON						varchar(4),
	prd1					integer,
	prd2					integer,
	prd3					integer,
	modprod					real,
	target					real,
    Narrative				varchar(240)
);
CREATE INDEX ConsultantTransactions_ClientID ON ConsultantTransactions (ClientID);
CREATE INDEX ConsultantTransactions_PeriodID ON ConsultantTransactions (PeriodID);

CREATE TABLE MIDTTransactions (
	MIDTTransactionID		serial primary key,
	ClientID				integer references Clients,
	PeriodID				integer references periods,
   	CRS						varchar(12),
   	PCC						varchar(25),
	Agency					varchar(120),	
	IATANo					varchar(50),
	prd						real
);
CREATE INDEX MIDTTransactions_ClientID ON MIDTTransactions (ClientID);
CREATE INDEX MIDTTransactions_PeriodID ON MIDTTransactions (PeriodID);
CREATE INDEX MIDTTransactions_CRS ON MIDTTransactions (CRS);

CREATE TABLE dailySegments (
	dailySegmentid			serial primary key,
	PRDDate					varchar(50),
	city					varchar(50),
	ndc						varchar(50),	
	PCC						varchar(50),
	DailyNetSegments		varchar(50),
	MTDNetSegments			varchar(50),
	YTDNetSegments			varchar(50),
	MTDactivebooksSegments	varchar(50),
	MTDactivecancelsSegments	varchar(50),
	MTDPassiveNetSegments	varchar(50),
	MTDPassiveNetCoupons	varchar(50),
	MTDOthernetcoupons		varchar(50),
	ActiveCancels			varchar(50),
	Otherticketed			varchar(50)
);

CREATE TABLE dailyTransactions (
	dailyTransactionid		serial primary key,
	clientid			integer references clients,
	PRDDate				date,
	PCC				varchar(12),
	DailyNetSegments		integer,
	MTDNetSegments			integer,
	YTDNetSegments			integer
);
CREATE INDEX dailyTransactions_ClientID ON dailyTransactions (ClientID);

CREATE TABLE new_Segments (
	new_Segments_ID			serial primary key,
	PCC						varchar(12),
	Agency_Name				varchar(12),
	Terminal_ID				varchar(12),
	Month_Year				varchar(12),
	NAB						varchar(12),
	NCB						varchar(12),
	NHB						varchar(12),
	NAAB					varchar(12),
	NPAB					varchar(12),
	BARS					varchar(12),
	PARS					varchar(12),
	BPRS					varchar(12),
	PPRS					varchar(12),
	Billable				varchar(12),
	SA_IC					varchar(12),
	SA_PR					varchar(12),
	SA_RR					varchar(12),
	SA_GA					varchar(12),
	SA_II					varchar(12),
	SA_DYO					varchar(12),
	SA_NDYO					varchar(12),
	NLAT					varchar(12),
	NRASL					varchar(12),
	NDNR					varchar(12),
	PDIN					varchar(12),
	GMIR					varchar(12),
	NGMIR					varchar(12),
	BBNS					varchar(12),
	NRS						varchar(12),
	Downloaddate			date not null default current_date,
	IsUploaded				boolean not null default false
);

CREATE TABLE incentive_types (
	incentive_type_id		serial primary key,
	incentive_type_name		varchar(50) not null,
	details					text
);

CREATE TABLE incentive_targets (
	incentive_target_id		serial primary key,
	incentive_type_id		integer references incentive_types,
	market_share			integer,
	target_segments			integer,
	incentive_rate			real
);
CREATE INDEX incentive_targets_incentive_type_id ON incentive_targets (incentive_type_id);

CREATE TABLE contracts (
	contract_id				serial primary key,
	incentive_type_id		integer references incentive_types,
	ClientGroupID			integer references ClientGroups,
	clientid				integer references clients,
	after_cost				boolean default true not null,
	market_share			real,
	competition_cost		real default 0 not null,
	business_volume			integer,
	contract_date			date default current_date,
	contract_end			date,
	signed					boolean default false not null,
	Bank_Name				varchar(50),
	Bank_Branch				varchar(50),
	Swift_code				varchar(50),
	account_Name			varchar(50),
	account_No				varchar(50),
	payment_frequecy		varchar(50),
	details					text
);
CREATE INDEX contracts_incentive_type_id ON contracts (incentive_type_id);
CREATE INDEX contracts_ClientGroupID ON contracts (ClientGroupID);
CREATE INDEX contracts_clientid ON contracts (clientid);

CREATE TABLE incentive_payments (
	incentive_payment_id	serial primary key,
	contract_id				integer not null references contracts,
	pay_year				integer,
	pay_quarter				integer,
	payment_date			date,
	amount					real,
	payment_reference		varchar(50)
);
CREATE INDEX incentive_payments_contract_id ON incentive_payments (contract_id);



