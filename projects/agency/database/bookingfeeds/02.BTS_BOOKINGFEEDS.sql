CREATE SEQUENCE seq_sms_id START WITH 1  INCREMENT BY 1 ;
ALTER SEQUENCE seq_sms_id RESTART WITH 1;

CREATE SEQUENCE seq_email_id START WITH 1  INCREMENT BY 1 ;
ALTER SEQUENCE seq_email_id RESTART WITH 1;

CREATE TABLE [dbo].[sms](
	[sms_id] [int] NOT NULL,
	[TravelOrderIdentifier] [int] NOT NULL,
	[pcc] [char](10) NULL,
	[son] [varchar](9) NULL,
	[is_sent] [int] NULL,
	[PhoneNbr] [varchar](50) NULL,
	[PassangerName] [varchar](150) NULL,
	[message] [text] NULL,
	[RecordLocator] [varchar](10) NULL,
	[HostEventTimeStamp] [datetime] NULL,
	[TicketNumber] [nchar](20) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY];

CREATE TABLE [dbo].[email](
	[email_id] [int] NOT NULL,
	[TravelOrderIdentifier] [int] NOT NULL,
	[pcc] [char](10) NULL,
	[son] [varchar](9) NULL,
	[PhoneNbr] [varchar](50) NULL,
	[PassangerName] [varchar](150) NULL,
	[message] [text] NULL,
	[RecordLocator] [varchar](10) NULL,
	[HostEventTimeStamp] [datetime] NULL,
	[is_picked] [int] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY];




CREATE FUNCTION dbo.GetFlights(@TravelOrderIdentifier as int, @line_break as varchar(10)) RETURNS varchar(MAX) AS
BEGIN
DECLARE 	@v_FlightList 				VarChar(MAX) = ''; -- , @line_break varchar(10) = CHAR(13) + CHAR(10) + '<br>' ;
SELECT @v_FlightList = 
	COALESCE (CASE WHEN @v_FlightList = ''
					THEN @line_break + [Carrier] + '-' + [FlightNbr] + ' ' + [FlightDate]  + ' ' + [CouponBoardPoint] + ' - ' + [CouponOffPoint]   + ' ' + [FlightTime] 
					ELSE @v_FlightList + @line_break + [Carrier] + '-' + [FlightNbr] + ' ' + [FlightDate] + ' ' + [CouponBoardPoint] + ' - ' + [CouponOffPoint]   + ' ' + [FlightTime] 
				END ,' ')
	FROM [GIDS_BTS].[dbo].[AirTktSeg]  WHERE[TravelOrderIdentifier] = @TravelOrderIdentifier;
	--PRINT @v_FlightList

RETURN @v_FlightList;
END;


CREATE FUNCTION GIDS_BTS.dbo.GetPassangerName(@TravelOrderIdentifier as int) RETURNS varchar(MAX) AS
BEGIN
DECLARE 	@v_PaxName 				VarChar(MAX) = '' ;
	SELECT @v_PaxName = [LastName] + ' ' + [FirstName]  FROM [GIDS_BTS].[dbo].[Passenger]  WHERE [TravelOrderIdentifier] = @TravelOrderIdentifier;
	--PRINT @v_PaxName

	RETURN @v_PaxName;
END;


CREATE VIEW vw_sms AS
	SELECT [sms_id], [TravelOrderIdentifier], [RecordLocator],[HostEventTimeStamp], [PhoneNbr],  [is_sent],
		[GIDS_BTS].[dbo].GetPassangerName([TravelOrderIdentifier]) + CHAR(10) + [TicketNumber] + [GIDS_BTS].[dbo].GetFlights([TravelOrderIdentifier], CHAR(10) ) AS message
	FROM [GIDS_BTS].[dbo].[sms];

	
	
  CREATE VIEW [dbo].[vw_email] AS
	SELECT [email_id], [TravelOrderIdentifier], [pcc],[son], [PhoneNbr], [GIDS_BTS].[dbo].GetPassangerName([TravelOrderIdentifier]) AS [PassangerName], [RecordLocator], [is_picked],[HostEventTimeStamp], 
		'PCC : ' + [pcc] 
		+ CHAR(13) + CHAR(10) + '<br>SON : ' + [son] 
		+ CHAR(13) + CHAR(10) + '<br>Time : ' + CAST([HostEventTimeStamp] AS VARCHAR) 
		+ CHAR(13) + CHAR(10) + '<hr>'
		+ CHAR(13) + CHAR(10) + '<br>Record Locator : '  + [RecordLocator]
		+ CHAR(13) + CHAR(10) + '<br>'
		+ CHAR(13) + CHAR(10) + '<br>' + [GIDS_BTS].[dbo].GetPassangerName([TravelOrderIdentifier])
		+ CHAR(13) + CHAR(10) + '<br>' + [GIDS_BTS].[dbo].GetFlights([TravelOrderIdentifier], (CHAR(13) + CHAR(10) + '<br>')) AS message
	FROM [GIDS_BTS].[dbo].[email];
	
	
CREATE TRIGGER [dbo].[ins_TktTrans] ON [GIDS_BTS].[dbo].[TktTrans] AFTER INSERT AS
BEGIN
	IF (SELECT ActiveVoidStatus  FROM INSERTED ) = 'A' 
	BEGIN
		DECLARE @v_RecordLocator 			varchar(10),	@v_TTravelOrderIdentifier 	int, 			@v_BTravelOrderIdentifier 	int, @v_THostEventTimeStamp	datetime;
		DECLARE @v_PhoneNbr					varchar(90),	@v_PassngerName				varchar(255), 	@v_FlightList 				varchar(255) = '' , @line_break varchar(5) = CHAR(13) + CHAR(10) ;
		DECLARE @v_OwningAgencyPseudo		varchar(5),		@v_TransactionAgent 		varchar(10);
		DECLARE @v_Message					varchar(255),	@v_TicketNumber 			varchar(50);
		
			SELECT @v_TicketNumber = [TransactionPlatingNbr] + '' + [TicketNbr] FROM INSERTED;
			SELECT @v_RecordLocator = [RecordLocator],
					@v_TTravelOrderIdentifier = [TravelOrderIdentifier], 
					@v_OwningAgencyPseudo = [OwningAgencyPseudo],
					@v_THostEventTimeStamp = DATEADD(hour,3, [HostEventTimeStamp]) , 
					@v_TransactionAgent = [TransactionAgent]  FROM [GIDS_BTS].[dbo].[TravelOrderEvent] WHERE [TravelOrderIdentifier] = (SELECT TravelOrderIdentifier FROM INSERTED);
					
			SELECT @v_PassngerName =  [GIDS_BTS].[dbo].GetPassangerName(@v_TTravelOrderIdentifier);
			
			SELECT @v_BTravelOrderIdentifier = MAX([TravelOrderIdentifier]) FROM [dbo].[TravelOrderEvent] WHERE [EventType] = 'B' AND [RecordLocator] = @v_RecordLocator;
	
			SELECT @v_PhoneNbr = [PhoneNbr] FROM [dbo].[PhoneSeg] WHERE [TravelOrderIdentifier] = @v_BTravelOrderIdentifier AND ([PhoneType] = 'B' OR [PhoneType] = 'R');
		
			SELECT @v_FlightList = [GIDS_BTS].[dbo].GetFlights(@v_TTravelOrderIdentifier, (CHAR(13) + CHAR(10) + '<br>'));
			
			SELECT @v_Message =  [GIDS_BTS].[dbo].GetFlights(@v_TTravelOrderIdentifier, (CHAR(13) + CHAR(10) + '<br>'));
		
			IF((LTRIM(RTRIM(@v_PhoneNbr))) IS NOT NULL  ) OR (LEN((LTRIM(RTRIM(@v_PhoneNbr)))) > 0)
				BEGIN
					INSERT INTO dbo.sms(sms_id ,TravelOrderIdentifier,pcc,son,is_sent,RecordLocator, PhoneNbr, PassangerName, message, HostEventTimeStamp, TicketNumber)
						(SELECT (NEXT VALUE FOR dbo.seq_sms_id), @v_TTravelOrderIdentifier, @v_OwningAgencyPseudo , @v_TransactionAgent, 0 ,@v_RecordLocator, @v_PhoneNbr, @v_PassngerName , @v_Message, @v_THostEventTimeStamp, @v_TicketNumber  );
				END
			
			IF (@v_THostEventTimeStamp >= CAST((CAST((CAST(@v_THostEventTimeStamp AS DATE)) AS VARCHAR) + ' 18:00:000') AS DATETIME))	AND (@v_THostEventTimeStamp  <= CAST((CAST((CAST((@v_THostEventTimeStamp) AS DATE)) AS VARCHAR) + ' 08:00:000') AS DATETIME) + 1)
				BEGIN
					INSERT INTO dbo.email(email_id ,TravelOrderIdentifier,pcc,son,is_picked,RecordLocator, PhoneNbr, PassangerName, message, HostEventTimeStamp)
						(SELECT (NEXT VALUE FOR dbo.seq_email_id), @v_TTravelOrderIdentifier, @v_OwningAgencyPseudo , @v_TransactionAgent, 0 ,@v_RecordLocator, @v_PhoneNbr, @v_PassngerName , @v_Message, @v_THostEventTimeStamp );
				END
	END
END