CREATE TABLE UserGroups (
	UserGroupID			serial primary key,
	UserGroupName		varchar(50) not null,
	Activities			text,
	Description			text
);

CREATE TABLE Users (
	UserID				serial primary key,
	UserGroupID			integer references UserGroups,
	SuperUser			boolean not null default false,
	RoleName			varchar(50),
	username			varchar(50) not null unique,
	FullName			varchar(50) not null unique,
	Extension 			varchar(12),
	TelNo				varchar(25),
	EMail				varchar(120),
	AccountManager		boolean default false,
	GroupLeader			boolean default false,
	IsActive			boolean default true,
	GroupUser			boolean default false,
	userpass			varchar(32) not null default md5('enter'),
	Details				text
);
CREATE INDEX Users_UserGroupID ON Users (UserGroupID);
CREATE INDEX Users_username ON Users (username);

CREATE OR REPLACE FUNCTION getUserID() RETURNS integer AS $$
	SELECT UserID FROM users WHERE (username = current_user);
$$ LANGUAGE SQL;

CREATE TABLE audittrail (
	audittrailid	serial primary key,
	username		varchar(50) not null,
	changedate		timestamp not null default now(),
	tablename		varchar(25) not null,
	recordid		varchar(25) not null,
	changetype		varchar(25) not null,
	narrative		varchar(120)
);

CREATE TABLE ClientAffiliates (
	ClientAffiliateID	serial primary key,
	ClientAffiliateName	varchar(50) not null,
	Detail				text
);

CREATE TABLE ClientGroups (
	ClientGroupID		serial primary key,
	ClientAffiliateID	integer references ClientAffiliates,
	ClientGroupName		varchar(50) not null,
	Detail				text
);
CREATE INDEX ClientGroups_ClientAffiliateID ON ClientGroups (ClientAffiliateID);

CREATE TABLE ClientSystems (
	ClientSystemID		serial primary key,
	ClientSystemName	varchar(50) not null,
	Details				text
);

CREATE TABLE ClientLinks (
	ClientLinkID		serial primary key,
	ClientLinkName		varchar(50) not null,
	Details				text
);

CREATE TABLE Clients (
	ClientID 			serial primary key,
	UserID				integer references Users,
	ClientGroupID		integer references ClientGroups,
	ClientSystemID		integer references ClientSystems,
	ClientLinkID		integer references ClientLinks,
	ClientName			varchar(50) not null,
	Address				varchar(50),
	ZipCode				varchar(12),
	Premises			varchar(120) not null,
	Street				varchar(120),
	Division			varchar(25),
	Town				varchar(50) not null,
	Country				varchar(50),
	TelNo				varchar(150),
	FaxNo				varchar(50),
	Email				varchar(120),
	website            	varchar(120),
	IATANo				varchar(12),
	IsIATA				boolean default false not null,
	clienttarget		integer,
	consultanttarget	integer,
	budget			    integer,
	Clientpass			varchar(32) not null default md5('hello'),
	DateEnroled			date default current_date,
	Connected			boolean not null default true,
	IsActive			boolean not null default true,
	contractdate		date,
	contractend			date,
	DateClosed			date,
	createdate			timestamp default now(),
	
	firstpasswd			varchar(32),
	
	Details				text
);
CREATE INDEX Clients_UserID ON Clients (UserID);
CREATE INDEX Clients_ClientGroupID ON Clients (ClientGroupID);
CREATE INDEX Clients_ClientSystemID ON Clients (ClientSystemID);
CREATE INDEX Clients_ClientLinkID ON Clients (ClientLinkID);

CREATE TABLE pccs	(
	pcc					varchar(12) primary key,
	ClientID			integer references Clients,
	gds					varchar(2) not null,
	pccdate				date default current_date
);
CREATE INDEX pccs_ClientID ON pccs (ClientID);		

CREATE TABLE Consultants (
	ConsultantID		serial primary key,
	ClientID			integer references Clients,
	salutation			varchar(7),
	firstname			varchar(50) not null,
	othernames			varchar(50),
	JobDefination		varchar(120),
	TelNo				varchar(25),
	cellphone			varchar(25),
	Email				varchar(120),
	birthdate			date,
	SON					varchar(4),
	agentpass			varchar(32) not null default md5('hello'),
	details				text
);
CREATE INDEX Consultants_ClientID ON Consultants (ClientID);

CREATE TABLE AffiliateTargets (
	AffiliateTargetID	serial primary key,
	ClientAffiliateID	integer references ClientAffiliates,
	target				integer not null,
	marketratio			real,
	costvariance		real,
	amount				real,
	narrative			varchar(120)
);
CREATE INDEX AffiliateTargets_ClientAffiliateID ON AffiliateTargets (ClientAffiliateID);

CREATE TABLE GroupTargets (
	GroupTargetID		serial primary key,
	ClientGroupID		integer references ClientGroups,
	target				integer not null,
	marketratio			real,
	costvariance		real,
	amount				real,
	narrative			varchar(120)
);
CREATE INDEX GroupTargets_ClientGroupID ON GroupTargets (ClientGroupID);

CREATE TABLE ConsultantRewards (
	ConsultantRewardID	serial primary key,
	Target				integer not null,
	Amount				real,
	Details				text
);

CREATE TABLE PClassifications (
	PClassificationID		serial primary key,
	PClassificationName		varchar(50) not null,
	Description				text
);

CREATE TABLE PTypes (
	PTypeID					serial primary key,
	PClassificationID		integer references PClassifications,
	PTypeName				varchar(50) not null,
	Description				text
);
CREATE INDEX PTypes_PClassificationID ON PTypes (PClassificationID);

CREATE TABLE PDefinitions (
	PDefinitionID			serial primary key,
	PTypeID					integer references PTypes,
	PDefinitionName			varchar(50)  not null,
	Description				text,
	Solution				text
);
CREATE INDEX PDefinitions_PTypeID ON PDefinitions (PTypeID);

CREATE TABLE Stages (
	StageID					serial primary key,
	PDefinitionID			integer references PDefinitions,
	UserID					integer references Users,
	TimeInterval			integer not null,
	StageOrder				integer not null,
	isDependent				boolean not null default false,
    isDelayedAction         boolean not null default false,
	IsForApproval			boolean not null default false,
	Task					varchar(240),
	Details					text
);
CREATE INDEX Stages_PDefinitionID ON Stages (PDefinitionID);
CREATE INDEX Stages_UserID ON Stages (UserID);

CREATE TABLE PLevels (
	PlevelID				serial primary key,
	PlevelName				varchar(50) not null unique,
	PlevelRatio				integer not null,
	Details					text
);

CREATE TABLE ProblemLog (
	ProblemLogID			serial primary key,
	PDefinitionID			integer references PDefinitions,
	ClientID				integer references Clients,
	PLevelID				integer references PLevels,
	UserID					integer references Users default getUserID(),
	Description				varchar(120) not null,
	ReportedBy				varchar(50) not null,
	RecodedTime				timestamp not null default now(),
	SolvedTime				timestamp,
	ClosedBy				integer references Users,
	IsSolved				boolean not null default false,
	CurrAction				varchar(50),
	CurrStatus				varchar(50),
	Problem					text,
	Solution				text
);
CREATE INDEX ProblemLog_PDefinitionID ON ProblemLog (PDefinitionID);
CREATE INDEX ProblemLog_ClientID ON ProblemLog (ClientID);
CREATE INDEX ProblemLog_PLevelID ON ProblemLog (PLevelID);
CREATE INDEX ProblemLog_UserID ON ProblemLog (UserID);
CREATE INDEX ProblemLog_ClosedBy ON ProblemLog (ClosedBy);
CREATE INDEX ProblemLog_IsSolved ON ProblemLog (IsSolved);

CREATE TABLE Helpdeskimages (
	helpdeskimageid			serial primary key,
	ProblemLogID			integer  not null references ProblemLog,	
	upload					bytea
);
CREATE INDEX Helpdeskimages_ProblemLogID ON helpdeskimages (ProblemLogID);

CREATE TABLE Forwarded (
	ForwardID 				serial primary key,
	ProblemLogID			integer  not null references ProblemLog,
	UserID					integer references Users,
	SenderID				integer references Users default getUserID(),
	ReferenceNo				varchar(50),
	Description				varchar(240),
	ForwardTime				timestamp not null default now(),
	LastEscalation			timestamp,
	SolvedTime				timestamp,
	TimeInterval            integer not null default 9,
	StageOrder				integer not null default 1,
	isDependent				boolean not null default false,
	IsSolved				boolean not null default false,
	IsDrop					boolean not null default false,	
	isDelayedAction         boolean not null default false,
	IsForApproval			boolean not null default false,
	SystemForward			boolean not null default false,
	tobedone				text,
	whatisdone				text
);
CREATE INDEX Forwarded_ProblemLogID ON Forwarded (ProblemLogID);
CREATE INDEX Forwarded_UserID ON Forwarded (UserID);
CREATE INDEX Forwarded_SenderID ON Forwarded (SenderID);

CREATE INDEX Forwarded_IsSolved ON Forwarded (IsSolved);
CREATE INDEX Forwarded_IsDrop ON Forwarded (IsDrop);

CREATE TABLE worktypes (
	worktypeid				serial primary key,
	worktypename			varchar(50) not null unique,
	details					text
);

CREATE TABLE WorkSchedule (
	WorkScheduleID			serial primary key,
    worktypeid				integer references worktypes,
	UserID					integer references Users default getUserID(),	
	WorkDate				date not null,
	narrative				varchar(250),
	HoursSpent				integer,
	IsDone					boolean not null default false,
	Details					text
);
CREATE INDEX WorkSchedule_worktypeid ON WorkSchedule (worktypeid);
CREATE INDEX WorkSchedule_UserID ON WorkSchedule (UserID);

CREATE TABLE FieldSupport (
	FieldSupportID			serial primary key,
    ClientID				integer references Clients,
	UserID					integer references Users default getUserID(),	
	SupportDate				date not null,
	Reason					varchar(50),	
	timeIn					time not null,
	HoursSpent				integer,
	IsDone					boolean not null,
	IsDrop					boolean default false not null,
	IsForAction				boolean default false not null,
	ActionDone				boolean default false not null,
	Details					text,
	Request					text,
	Observations			text,
	Recommendation			text
);
CREATE INDEX FieldSupport_ClientID ON FieldSupport (ClientID);
CREATE INDEX FieldSupport_UserID ON FieldSupport (UserID);

CREATE TABLE Cars (
	CarID					serial primary key,
	CarName					varchar(50) not null,
	available				boolean not null default true,
	NextService				date,
	Details					text
);

CREATE TABLE CarServices (
	CarServiceID			serial primary key,
	CarID					integer references Cars,
	ServiceDate				date,
	ServiceMillage			integer,
	problems				text,
	replacements			text
);
CREATE INDEX CarServices_CarID ON CarServices (CarID);

CREATE TABLE Transport (
	TransportID				serial primary key,
	CarID					integer references Cars,
	UserID					integer references Users default getUserID(),
	TransportDate			date not null,
	Booktime				time not null,
	TimeGone				integer not null,
	ReturnTime				time,
	HoursSpent				integer,
	Location				varchar(50),
	SelfDriven				boolean default false not null,
	taxi					boolean default false not null,
	personalcar				boolean default false not null,
	IsApproved				boolean default false not null,
	IsDone					boolean default false not null,
	IsDrop					boolean default false not null,
	keysreturned			boolean default false not null,
	MillageClaims			float,
	TaxiFare				float,
	SMillage				integer,
	Emillage				integer,
	Details					text
);
CREATE INDEX Transport_CarID ON Transport (CarID);
CREATE INDEX Transport_UserID ON Transport (UserID);

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
	UserID					integer references Users default getUserID(),
	Replacement				boolean not null default false,
	Quantity				integer,
	Details					text
);
CREATE INDEX ERF_ProblemLogID ON ERF (ProblemLogID);
CREATE INDEX ERF_AssetSubTypeID ON ERF (AssetSubTypeID);
CREATE INDEX ERF_UserID ON ERF (UserID);

CREATE TABLE Assets (
	AssetID	 				serial primary key,
	AssetSubTypeID			integer references AssetSubTypes,
	AssetSN					varchar(32) not null,
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
	UserID					integer references Users,
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
CREATE INDEX Transactions_UserID ON Transactions (UserID);

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
   	CRS 					varchar(12),
   	PCC						varchar(25),
	Agency					varchar(120),	
	IATANo					varchar(50),
	prd						real
);
CREATE INDEX MIDTTransactions_ClientID ON MIDTTransactions (ClientID);
CREATE INDEX MIDTTransactions_PeriodID ON MIDTTransactions (PeriodID);
CREATE INDEX MIDTTransactions_CRS ON MIDTTransactions (CRS);

CREATE TABLE calldumps (
	calldumpID				serial primary key,
	calldate				varchar(25),
	callmarker				varchar(25),
	calltime				varchar(25),
	extension				varchar(25),
	callline				varchar(25),
	calldetails				varchar(50),
	talktime				varchar(25),
	callcode				varchar(25),
	Downloaddate			date not null default current_date,
	IsUploaded				boolean not null default false
);

CREATE TABLE calls (
	callID					serial primary key,
	calldate				date,
	callmarker				varchar(3),
	calltime				time,
	extension				varchar(12),
	callline				varchar(12),
	calldetails				varchar(50),
	talktime				float,
	callcode				varchar(12)
);

CREATE TABLE TrainingTypes (
	TrainingTypeID			serial primary key,
	TrainingTypeName		varchar(50) not null unique,
	Details					text
);

CREATE TABLE Training (
	TrainingID				serial primary key,
	UserID					integer references Users,
	TrainingTypeID			integer references TrainingTypes,
	StartDate				date,
	StopDate				date,
	IsDone					boolean,
	Amount					float,
	maxclass				integer,
	Details					text
);
CREATE INDEX Training_UserID ON Training (UserID);
CREATE INDEX Training_TrainingTypeID ON Training (TrainingTypeID);

CREATE TABLE ClientTraining (
	ClientTrainingID		serial primary key,
	TrainingID				integer references training,
	ConsultantID			integer references Consultants,
	IsDone					boolean not null,
	IsPaid					boolean not null default false,
	IsCert					boolean not null default false,
	IsCompleted				boolean not null default false,
	Marks					integer,
	Details					text
);
CREATE INDEX ClientTraining_TrainingID ON ClientTraining (TrainingID);
CREATE INDEX ClientTraining_ConsultantID ON ClientTraining (ConsultantID);

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



