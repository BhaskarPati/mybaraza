
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

CREATE TABLE Clients (
	ClientID 			serial primary key,
	entity_id			integer references entitys,
	ClientGroupID		integer references ClientGroups,
	ClientName			varchar(120),
	Address				varchar(50),
	ZipCode				varchar(16),
	Premises			varchar(120),
	Street				varchar(120),
	Division			varchar(50),
	Town				varchar(50) not null,
	Country				varchar(50),
	TelNo				varchar(320),
	FaxNo				varchar(50),
	Email				varchar(320),
	website            	varchar(120),
	IATANo				varchar(50),
	IsIATA				boolean default false not null,
	mst_cus_id			varchar(10),
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
CREATE INDEX Clients_entity_id ON Clients (entity_id);
CREATE INDEX Clients_ClientGroupID ON Clients (ClientGroupID);

CREATE TABLE pccs	(
	pcc					varchar(60) primary key,
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
	entity_id				integer references entitys,
	TimeInterval			integer not null,
	StageOrder				integer not null,
	isDependent				boolean not null default false,
    isDelayedAction         boolean not null default false,
	IsForApproval			boolean not null default false,
	Task					varchar(240),
	Details					text
);
CREATE INDEX Stages_PDefinitionID ON Stages (PDefinitionID);
CREATE INDEX Stages_entity_id ON Stages (entity_id);

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
	entity_id				integer references entitys,
	updated_by				integer references entitys,
	closed_by				integer references entitys,
	Description				varchar(120) not null,
	ReportedBy				varchar(50) not null,
	RecodedTime				timestamp not null default now(),
	SolvedTime				timestamp,
	IsSolved				boolean not null default false,
	CurrAction				varchar(50),
	CurrStatus				varchar(50),
	Problem					text,
	Solution				text
);
CREATE INDEX ProblemLog_PDefinitionID ON ProblemLog (PDefinitionID);
CREATE INDEX ProblemLog_ClientID ON ProblemLog (ClientID);
CREATE INDEX ProblemLog_PLevelID ON ProblemLog (PLevelID);
CREATE INDEX ProblemLog_entity_id ON ProblemLog (entity_id);
CREATE INDEX ProblemLog_updated_by ON ProblemLog (updated_by);
CREATE INDEX ProblemLog_closed_by ON ProblemLog (closed_by);
CREATE INDEX ProblemLog_IsSolved ON ProblemLog (IsSolved);

CREATE TABLE Forwarded (
	ForwardID 				serial primary key,
	ProblemLogID			integer  not null references ProblemLog,
	entity_id				integer references entitys,
	updated_by				integer references entitys,
	sender_id				integer references entitys,
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
CREATE INDEX Forwarded_entity_id ON Forwarded (entity_id);
CREATE INDEX Forwarded_updated_by ON Forwarded (updated_by);
CREATE INDEX Forwarded_sender_id ON Forwarded (sender_id);

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
	entity_id				integer references entitys,
	WorkDate				date not null,
	narrative				varchar(250),
	HoursSpent				integer,
	IsDone					boolean not null default false,
	Details					text
);
CREATE INDEX WorkSchedule_worktypeid ON WorkSchedule (worktypeid);
CREATE INDEX WorkSchedule_entity_id ON WorkSchedule (entity_id);

CREATE TABLE FieldSupport (
	FieldSupportID			serial primary key,
    ClientID				integer references Clients,
	entity_id				integer references entitys,
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
CREATE INDEX FieldSupport_entity_id ON FieldSupport (entity_id);

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
	entity_id				integer references entitys,
	TransportDate			date not null,
	Booktime				time not null,
	ReturnTime				time not null,
	Returned				time,
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
CREATE INDEX Transport_entity_id ON Transport (entity_id);

CREATE TABLE TrainingTypes (
	TrainingTypeID			serial primary key,
	TrainingTypeName		varchar(50) not null unique,
	Details					text
);

CREATE TABLE Training (
	TrainingID				serial primary key,
	entity_id				integer references entitys,
	TrainingTypeID			integer references TrainingTypes,
	StartDate				date,
	StopDate				date,
	IsDone					boolean,
	Amount					float,
	maxclass				integer,
	Details					text
);
CREATE INDEX Training_entity_id ON Training (entity_id);
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

