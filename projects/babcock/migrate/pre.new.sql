CREATE TABLE UserGroups (
	UserGroupID		serial primary key,
	UserGroupName	varchar(50) not null,
	Activities		text,
	Description		text
);

CREATE TABLE Users (
	UserID			serial primary key,
	UserGroupID		integer references UserGroups,
	SuperUser		boolean not null default false,
	RoleName		varchar(50),
	username		varchar(50) not null unique,
	FullName		varchar(50) not null unique,
	Extension 		varchar(12),
	TelNo			varchar(25),
	EMail			varchar(120),	
	AccountManager	boolean default false,
	GroupLeader		boolean default false,
	IsActive		boolean default true,
	GroupUser		boolean default false,
	userpasswd		varchar(32) not null default md5('enter'),
	firstpasswd		varchar(32) not null default 'enter',			
	Details			text
);
CREATE INDEX Users_UserGroupID ON Users (UserGroupID);

ALTER TABLE students ADD 	firstpasswd			varchar(32);
ALTER TABLE students ADD 	userpasswd			varchar(32);
ALTER TABLE students ADD 	guardianfpasswd		varchar(32);
ALTER TABLE students ADD 	guardianpasswd		varchar(32);
