
CREATE VIEW ClientGroupView AS
	SELECT ClientAffiliates.ClientAffiliateName, ClientGroups.ClientGroupID, ClientGroups.ClientAffiliateID, 
		ClientGroups.ClientGroupName
	FROM ClientAffiliates INNER JOIN ClientGroups ON ClientAffiliates.ClientAffiliateID = ClientGroups.ClientAffiliateID;
	
CREATE VIEW ClientView AS
	SELECT ClientGroupView.ClientAffiliateID, ClientGroupView.ClientAffiliateName, 
		ClientGroupView.ClientGroupID, ClientGroupView.ClientGroupName,
 		entitys.entity_id, entitys.entity_name, 
		Clients.ClientID, Clients.ClientName, Clients.Address, Clients.ZipCode, Clients.Premises, Clients.Street, Clients.Division,
		Clients.Town, Clients.Country, Clients.TelNo, Clients.FaxNo, Clients.email, Clients.website, Clients.IATANo, Clients.IsIATA,
		Clients.clienttarget, Clients.consultanttarget, Clients.budget, Clients.DateEnroled, Clients.Connected, Clients.IsActive,
		Clients.contractdate, Clients.contractend, Clients.DateClosed, clients.mst_cus_id,
		aa.pcc, substring(Clients.clientname, '.') as aid
	FROM ClientGroupView INNER JOIN Clients ON ClientGroupView.ClientGroupID = Clients.ClientGroupID
		INNER JOIN entitys ON Clients.entity_id = entitys.entity_id
		LEFT JOIN (SELECT ClientID, max(pcc) as pcc FROM pccs GROUP BY ClientID) aa
			ON Clients.ClientID = aa.ClientID;

CREATE VIEW ClientAList AS
	SELECT aid
	FROM clientview
	GROUP BY aid
	ORDER BY aid;

CREATE VIEW ClientTownView AS
	SELECT Town
	FROM clientview
	GROUP BY town
	ORDER BY town;

CREATE VIEW pccview AS
	SELECT clients.clientid, clients.clientname, Clients.Address, Clients.ZipCode, Clients.Premises, 
		Clients.Street, Clients.Division, Clients.Town, Clients.Country, Clients.TelNo, 
		Clients.FaxNo, Clients.email, Clients.website, Clients.IATANo, Clients.IsIATA,
		pccs.pcc, pccs.gds, pccs.pccdate
	FROM pccs INNER JOIN clients ON pccs.clientid = clients.clientid;

CREATE VIEW ConsultantView AS
	SELECT Clients.ClientID, Clients.ClientName, Consultants.ConsultantID, Consultants.salutation, Consultants.firstname, Consultants.othernames,
		Consultants.JobDefination, Consultants.TelNo, Consultants.cellphone, Consultants.email,
		Consultants.birthdate, Consultants.SON,
		(COALESCE(Consultants.salutation || ', ', '')  || COALESCE(Consultants.firstname, '') || COALESCE(', ' || Consultants.othernames, '')) as consultantname,
		(ClientName || ': ' || COALESCE(Consultants.salutation || ', ', '')  || COALESCE(Consultants.firstname, '') || COALESCE(', ' || Consultants.othernames, '')) as consultant_disp

	FROM Clients INNER JOIN Consultants ON Clients.ClientID = Consultants.ClientID;

---------------------------------------------------- helpdesk

CREATE VIEW PTypeView AS
	SELECT PClassifications.PClassificationID, PClassifications.PClassificationName, PTypes.PTypeID, PTypes.PTypeName, PTypes.Description
	FROM (PClassifications INNER JOIN PTypes ON PClassifications.PClassificationID = PTypes.PClassificationID)
	ORDER BY PClassifications.PClassificationName, PTypes.PTypeName;

CREATE VIEW PDefinitionview AS
	SELECT PClassifications.PClassificationID, PClassifications.PClassificationName, PTypes.PTypeID, PTypes.PTypeName,
		PDefinitions.PDefinitionID, PDefinitions.PDefinitionName, PDefinitions.Description, PDefinitions.Solution,
		(PClassifications.PClassificationName || ' : ' || PTypes.PTypeName || ' : ' || PDefinitions.PDefinitionName) as disp
	FROM PClassifications INNER JOIN PTypes ON PClassifications.PClassificationID = PTypes.PClassificationID
		INNER JOIN PDefinitions ON PTypes.PTypeID = PDefinitions.PTypeID
	ORDER BY PClassifications.PClassificationName, PTypes.PTypeName;

CREATE VIEW stageview AS
	SELECT entitys.entity_id, entitys.entity_name, stages.StageID, stages.PDefinitionID, stages.TimeInterval, 
		stages.StageOrder, stages.isDependent, stages.Task
	FROM stages INNER JOIN entitys ON stages.entity_id = entitys.entity_id
	ORDER BY stages.StageOrder;

CREATE VIEW definestageview AS
	SELECT PDefinitionview.PClassificationid, PDefinitionview.PClassificationName, PDefinitionview.PTypeid, PDefinitionview.PTypeName,
		PDefinitionview.PDefinitionid, PDefinitionview.PDefinitionName, stageview.stageid,
		stageview.entity_name, stageview.TimeInterval, stageview.StageOrder, stageview.isDependent, stageview.Task
	FROM PDefinitionview INNER JOIN stageview ON PDefinitionview.PDefinitionID = stageview.PDefinitionID
	ORDER BY PDefinitionview.PClassificationName, PDefinitionview.PTypeName, PDefinitionview.PDefinitionName, stageview.StageOrder;

CREATE VIEW ProblemLogView AS
	SELECT PDefinitionview.PClassificationID, PDefinitionview.PClassificationName, PDefinitionview.PTypeID,
		PDefinitionview.PTypeName, PDefinitionview.PDefinitionID, PDefinitionview.PDefinitionName,
		Clients.ClientID, Clients.ClientName, entitys.entity_type_id, entitys.entity_id, entitys.entity_name, entitys.primary_email,
		PLevels.PLevelID, PLevels.PLevelName, PLevels.PlevelRatio,
		ProblemLog.ProblemLogID, ProblemLog.Description, ProblemLog.ReportedBy, 
		ProblemLog.RecodedTime, ProblemLog.IsSolved, ProblemLog.SolvedTime, ProblemLog.CurrAction, 
		ProblemLog.CurrStatus, ProblemLog.problem, ProblemLog.solution,
		ProblemLog.closed_by, cl.entity_name as closedbyname,
		getWorkHours(ProblemLog.RecodedTime, ProblemLog.SolvedTime) as WorkHours,
		getWorkHours(ProblemLog.RecodedTime, ProblemLog.SolvedTime) / 9 as WorkDays,
		getProblemDrop(ProblemLog.ProblemLogID) as ProblemDrop,
		getProblemOpen(ProblemLog.ProblemLogID) as ProblemOpen
	FROM ProblemLog INNER JOIN PDefinitionview ON ProblemLog.PDefinitionID = PDefinitionview.PDefinitionID
		INNER JOIN Clients ON ProblemLog.ClientID = Clients.ClientID		
		INNER JOIN PLevels ON ProblemLog.PlevelID = PLevels.PLevelID
		INNER JOIN entitys ON problemLog.entity_id = entitys.entity_id
		LEFT JOIN entitys cl ON problemLog.closed_by = cl.entity_id;

CREATE VIEW ForwardedView AS
	SELECT entitys.entity_type_id, entitys.entity_id, entitys.user_name, entitys.entity_name, entitys.primary_email, 
		Forwarded.ForwardID, Forwarded.Sender_ID, cl.entity_name as SenderName, Forwarded.ProblemLogID,
		Forwarded.ReferenceNo, Forwarded.StageOrder, Forwarded.IsDependent, Forwarded.isDelayedAction,
		Forwarded.Description, Forwarded.ForwardTime, Forwarded.SolvedTime, Forwarded.IsSolved, Forwarded.IsDrop,
		Forwarded.TimeInterval,	Forwarded.LastEscalation, Forwarded.tobedone, Forwarded.whatisdone,
		getDependent(Forwarded.ForwardID) as dependent, getLastTime(Forwarded.ForwardID) as lasttime,
		getWorkHours(Forwarded.ForwardTime, Forwarded.SolvedTime) as ForwardHours,
		getWorkHours(getLastTime(Forwarded.ForwardID), Forwarded.SolvedTime) as EscalationHours
	FROM Forwarded INNER JOIN entitys ON Forwarded.entity_id = entitys.entity_id
		LEFT JOIN entitys cl ON Forwarded.Sender_ID = cl.entity_id
	ORDER BY Forwarded.StageOrder;

CREATE VIEW ProblemForwardView AS
	SELECT ProblemLogView.PClassificationID, ProblemLogView.PClassificationName, ProblemLogView.PTypeID, ProblemLogView.PTypeName,
		ProblemLogView.PDefinitionID, ProblemLogView.PDefinitionName, ProblemLogView.ClientID, ProblemLogView.ClientName,
		ProblemLogView.entity_type_id, ProblemLogView.entity_id, ProblemLogView.entity_name, ProblemLogView.primary_email, 
		ProblemLogView.PLevelID, ProblemLogView.PLevelName,
		ProblemLogView.PlevelRatio,	ProblemLogView.ProblemLogID,  ProblemLogView.Description,
		ProblemLogView.ReportedBy, ProblemLogView.RecodedTime, ProblemLogView.IsSolved, ProblemLogView.SolvedTime, ProblemLogView.CurrAction,
		ProblemLogView.CurrStatus, ProblemLogView.problem, ProblemLogView.solution, ProblemLogView.WorkHours,
		ProblemLogView.WorkDays, ProblemLogView.closed_by, ProblemLogView.closedbyname,
		ForwardedView.entity_type_id as fdgroupid, ForwardedView.entity_id as fdentity_id, ForwardedView.user_name as fdusername, 
		ForwardedView.entity_name as fdfullname, ForwardedView.primary_email as fdemail, ForwardedView.ForwardID, 
		ForwardedView.sender_id, ForwardedView.SenderName, ForwardedView.isDelayedAction,
		ForwardedView.ReferenceNo, ForwardedView.StageOrder, ForwardedView.IsDependent,
		ForwardedView.Description as fdDescription, ForwardedView.ForwardTime, ForwardedView.SolvedTime as fdSolvedTime,
		ForwardedView.IsSolved as fdsolved, ForwardedView.TimeInterval,	ForwardedView.LastEscalation, 
		ForwardedView.tobedone, ForwardedView.whatisdone, ForwardedView.dependent, ForwardedView.IsDrop,
		ForwardedView.lasttime, ForwardedView.ForwardHours, ForwardedView.EscalationHours,
		(ForwardedView.TimeInterval * ProblemLogView.PlevelRatio / 100) as EscalationTime
	FROM ProblemLogView INNER JOIN ForwardedView ON ProblemLogView.ProblemLogID = ForwardedView.ProblemLogID;

CREATE VIEW EsclationForwardView AS
	SELECT ProblemForwardView.PClassificationID, ProblemForwardView.PClassificationName, ProblemForwardView.PTypeID, 
		ProblemForwardView.PTypeName, ProblemForwardView.PDefinitionID, ProblemForwardView.PDefinitionName,
		ProblemForwardView.ClientID, ProblemForwardView.ClientName, ProblemForwardView.entity_type_id, ProblemForwardView.entity_id,
		ProblemForwardView.entity_name, ProblemForwardView.primary_email, ProblemForwardView.PLevelID, ProblemForwardView.PLevelName, 
		ProblemForwardView.PlevelRatio,	ProblemForwardView.ProblemLogID, ProblemForwardView.Description, ProblemForwardView.ReportedBy, 
		ProblemForwardView.RecodedTime, ProblemForwardView.IsSolved, ProblemForwardView.SolvedTime, ProblemForwardView.CurrAction, 
		ProblemForwardView.CurrStatus, ProblemForwardView.problem, ProblemForwardView.solution,
		ProblemForwardView.fdentity_id, ProblemForwardView.fdgroupid, ProblemForwardView.fdusername, 
		ProblemForwardView.fdfullname, ProblemForwardView.ForwardID, ProblemForwardView.fdEMail, 
		ProblemForwardView.sender_id, ProblemForwardView.SenderName, ProblemForwardView.isDelayedAction,
		ProblemForwardView.ReferenceNo, ProblemForwardView.StageOrder, ProblemForwardView.IsDependent,
		ProblemForwardView.fdDescription, ProblemForwardView.ForwardTime, ProblemForwardView.fdSolvedTime, 
		ProblemForwardView.fdsolved, ProblemForwardView.TimeInterval, ProblemForwardView.LastEscalation, 
		ProblemForwardView.tobedone, ProblemForwardView.whatisdone, ProblemForwardView.EscalationTime,
		ProblemForwardView.WorkHours, ProblemForwardView.dependent, ProblemForwardView.IsDrop,
		ProblemForwardView.lasttime, ProblemForwardView.ForwardHours, ProblemForwardView.EscalationHours,		
		(ProblemForwardView.fdFullName || ' <' || ProblemForwardView.fdemail || '>') as emailaddress,
		('CRM : ' || ProblemLogID || ' : ' || ProblemForwardView.ClientName || ' : ' || ProblemForwardView.PClassificationName) as emailsubject,
		getCountERF(ProblemForwardView.ProblemLogID) as counterf
	FROM ProblemForwardView
	WHERE (ProblemForwardView.IsSolved = false) AND (ProblemForwardView.fdSolved = false) AND (ProblemForwardView.IsDrop = false) AND (ProblemForwardView.dependent = false)
	AND ((ProblemForwardView.LastEscalation is null) OR (getWorkHours(ProblemForwardView.LastEscalation, LOCALTIMESTAMP)>ProblemForwardView.TimeInterval));


----------------------------------------------- Field Support

CREATE VIEW WorkScheduleView AS
	SELECT entitys.entity_id, entitys.entity_name, worktypes.worktypeid, worktypes.worktypename,
		WorkSchedule.WorkScheduleID, WorkSchedule.WorkDate, WorkSchedule.narrative,
		WorkSchedule.HoursSpent, WorkSchedule.IsDone, WorkSchedule.Details
	FROM (worktypes INNER JOIN WorkSchedule ON worktypes.worktypeid = WorkSchedule.worktypeid)
		INNER JOIN entitys ON WorkSchedule.entity_id = entitys.entity_id;;

CREATE VIEW FieldSupportView AS
	SELECT Clients.ClientName, entitys.entity_name, FieldSupport.FieldSupportID, FieldSupport.entity_id, FieldSupport.ClientID,
		FieldSupport.SupportDate, FieldSupport.Reason, FieldSupport.HoursSpent, FieldSupport.timeIn, 
		FieldSupport.IsDone, FieldSupport.IsDrop, FieldSupport.IsForAction, ActionDone
	FROM Clients INNER JOIN FieldSupport ON Clients.ClientID = FieldSupport.ClientID
		INNER JOIN entitys ON FieldSupport.entity_id = entitys.entity_id;;
	
CREATE VIEW TransportView AS
	SELECT Cars.CarName, entitys.entity_name, Transport.TransportID, Transport.CarID, Transport.entity_id, Transport.TransportDate, 
		Transport.booktime,	Transport.Location, Transport.IsDone, Transport.IsApproved,
		Transport.ReturnTime, Transport.HoursSpent, Transport.keysreturned, Transport.taxi,
		Transport.personalcar, Transport.SelfDriven, Transport.IsDrop, Transport.Returned,
		(ReturnTime - Booktime) as TimeGone
	FROM Transport LEFT JOIN Cars on Cars.CarID = Transport.CarID
		INNER JOIN entitys ON Transport.entity_id = entitys.entity_id;
		
CREATE VIEW CarServiceView AS
	SELECT Cars.CarID, Cars.CarName, Cars.NextService, CarServices.CarServiceID, CarServices.ServiceDate,
		CarServices.problems, CarServices.replacements
	FROM Cars INNER JOIN CarServices ON Cars.CarID = CarServices.CarID;

CREATE VIEW hourview AS
	SELECT CAST((generate_series || ':00') AS time) as hourvalue FROM generate_series(8,17);

CREATE VIEW dayview AS
	SELECT (date '2004-01-01' + generate_series) as dayvalue FROM generate_series(0, 3000);

CREATE VIEW calendarview AS
	SELECT dayview.dayvalue, hourview.hourvalue FROM dayview CROSS JOIN hourview;

CREATE VIEW calendarcar AS
	SELECT cars.carid, cars.carname, calendarview.dayvalue, calendarview.hourvalue,
		getcaravailable(cars.carid, calendarview.dayvalue, calendarview.hourvalue, calendarview.hourvalue + interval '1 hour') as carsapproved,
		getcarbooked(cars.carid, calendarview.dayvalue, calendarview.hourvalue, calendarview.hourvalue + interval '1 hour') as carsbooked
	FROM cars CROSS JOIN calendarview;

---------------------------------------- Assets

CREATE VIEW AssetSubTypeView AS
	SELECT AssetTypes.AssetTypeID, AssetTypes.AssetTypeName, AssetSubTypes.AssetSubTypeID, AssetSubTypes.AssetSubTypeName,
		AssetSubTypes.ClientCost, AssetSubTypes.segments
	FROM AssetTypes INNER JOIN AssetSubTypes ON AssetTypes.AssetTypeID = AssetSubTypes.AssetTypeID;

CREATE VIEW AssetsView AS
	SELECT AssetTypes.AssetTypeID, AssetTypes.AssetTypeName,
		AssetSubTypes.AssetSubTypeID, AssetSubTypes.AssetSubTypeName, AssetSubTypes.Clientcost, AssetSubTypes.segments,
		Assets.AssetID, Assets.AssetSN, Assets.IsInStore, Assets.Purchasedate, Assets.IsOnLease, Assets.PurchaseCost, 
		Assets.MonthlyCost, Assets.MonthlyMaintenance, Assets.Condition, Assets.WarrantyPeriod,
		Assets.SingularItem, Assets.sold, Assets.Saledate, Assets.saleamount, Assets.soldto, Assets.lost,
		getClientAsset(Assets.AssetID) as ClientAssetCount,
		(Purchasedate + CAST(WarrantyPeriod || ' month' AS interval)) as WarrantyEnd 
	FROM (AssetTypes INNER JOIN AssetSubTypes ON AssetTypes.AssetTypeID = AssetSubTypes.AssetTypeID)
		INNER JOIN Assets ON AssetSubTypes.AssetSubTypeID = Assets.AssetSubTypeID;

CREATE VIEW DuplicateSNView AS
	SELECT AssetSubTypeID, AssetSubTypeName, assetsn, count(assetid)
	FROM AssetsView
	WHERE (SingularItem=true)
	GROUP BY AssetSubTypeID, AssetSubTypeName, assetsn
	HAVING count(assetid)>1;

CREATE VIEW ClientAssetView AS
	SELECT AssetsView.AssetTypeID, AssetsView.AssetTypeName, AssetsView.AssetSubTypeID, AssetsView.AssetSubTypeName, 
		AssetsView.Clientcost, AssetsView.segments, AssetsView.AssetSN, AssetsView.lost,
		AssetsView.IsInStore, AssetsView.Purchasedate, AssetsView.IsOnLease, AssetsView.PurchaseCost,
		AssetsView.WarrantyPeriod, AssetsView.SingularItem, AssetsView.ClientAssetCount, AssetsView.WarrantyEnd, 
		ClientGroups.ClientGroupid, ClientGroups.ClientGroupname, Clients.clientid, Clients.ClientName, 
		ClientAssets.ClientAssetID, ClientAssets.AssetID, ClientAssets.IsIssued, 
		ClientAssets.dateIssued, ClientAssets.IsRetrived, ClientAssets.dateRetrived, ClientAssets.Narrative,
		ClientAssets.crmrefno, ClientAssets.dnoteno, ClientAssets.rcrmrefno, ClientAssets.rdnoteno, ClientAssets.units,
		(assetsubtypename || ', ' || assetsn) as asset_disp,
		(AssetsView.Clientcost * ClientAssets.units) as assetcost, (AssetsView.segments * ClientAssets.units) as assetsegments
	FROM (AssetsView INNER JOIN ClientAssets ON AssetsView.AssetID = ClientAssets.AssetID)
	INNER JOIN (Clients INNER JOIN ClientGroups ON Clients.ClientGroupid = ClientGroups.ClientGroupid)
		ON Clients.ClientID = ClientAssets.ClientID;

CREATE VIEW clientassetcount AS
	SELECT clientid, clientname, assetsubtypeid, assetsubtypename, sum(units) as totalunits, 
		sum(assetcost) as totalcost, sum(assetsegments) as totalsegments
	FROM ClientAssetView
	WHERE (IsIssued = true) AND (IsRetrived = false)
	GROUP BY clientid, clientname, assetsubtypeid, assetsubtypename
	ORDER BY clientname;

CREATE VIEW groupassetcount AS
	SELECT clientgroupid, clientgroupname, assetsubtypeid, assetsubtypename, sum(units) as totalunits, 
		sum(assetcost) as totalcost, sum(assetsegments) as totalsegments
	FROM ClientAssetView
	WHERE (IsIssued = true) AND (IsRetrived = false)
	GROUP BY clientgroupid, clientgroupname, assetsubtypeid, assetsubtypename
	ORDER BY clientgroupname;

CREATE VIEW clientassetcost AS
	SELECT clientid, clientname, sum(assetcost) as totalcost, sum(assetsegments) as totalsegments
	FROM ClientAssetView
	WHERE (IsIssued = true) AND (IsRetrived = false)
	GROUP BY clientid, clientname
	ORDER BY clientname;

CREATE VIEW PCConfigurationView AS
	SELECT Clients.ClientName, PCConfiguration.PCConfigurationID, PCConfiguration.ClientID, PCConfiguration.CPUSN,
		PCConfiguration.FPNET, PCConfiguration.FPConfig, PCConfiguration.ISP, PCConfiguration.Orderdate,
		PCConfiguration.ConfigNumber, PCConfiguration.IPAddress, PCConfiguration.SubnetMask, PCConfiguration.GIClientID,
		PCConfiguration.IWSGTID, PCConfiguration.Printer1GTID, PCConfiguration.Printer2GTID
	FROM Clients INNER JOIN PCConfiguration ON Clients.ClientID = PCConfiguration.ClientID;

CREATE VIEW ERFView AS
	SELECT entitys.entity_id, entitys.entity_name, AssetSubTypes.AssetSubTypeID, AssetSubTypes.AssetSubTypeName,
		AssetSubTypes.ClientCost, AssetSubTypes.segments, 
		ERF.ERFID, ERF.ProblemLogID, ERF.Replacement, ERF.Quantity,
		(CASE WHEN ERF.Replacement = false THEN (ERF.Quantity * AssetSubTypes.ClientCost) ELSE 0 END) as erfcost, 
		(CASE WHEN ERF.Replacement = false THEN (ERF.Quantity * AssetSubTypes.segments) ELSE 0 END) as erfsegments 
	FROM ERF INNER JOIN AssetSubTypes ON AssetSubTypes.AssetSubTypeID = ERF.AssetSubTypeID
	INNER JOIN entitys ON ERF.entity_id = entitys.entity_id;;;

CREATE VIEW ForwardERFView AS
	SELECT ForwardedView.entity_type_id, ForwardedView.entity_id, ForwardedView.user_name, ForwardedView.entity_name, 
		ForwardedView.ForwardID, ForwardedView.ProblemLogID, ForwardedView.ReferenceNo, ForwardedView.StageOrder,
		ForwardedView.IsDependent, ForwardedView.Description, ForwardedView.ForwardTime, ForwardedView.SolvedTime,
		ForwardedView.IsSolved, ERFView.entity_name AS RequestedBy, ERFView.AssetSubTypeID, ERFView.AssetSubTypeName,
		ERFView.ClientCost, ERFView.segments, ERFView.ERFID, ERFView.Quantity, ERFView.erfcost, ERFView.erfsegments
	FROM ForwardedView INNER JOIN ERFView ON ForwardedView.ProblemLogID = ERFView.ProblemLogID;

CREATE VIEW vw_client_assets AS
	SELECT AssetsView.assettypeid, AssetsView.assettypename, AssetsView.assetsubtypeid, 
		AssetsView.assetsubtypename, AssetsView.assetsn,
		AssetsView.assetid, AssetsView.purchasedate, AssetsView.isonlease, 
		(CASE WHEN AssetsView.sold = false THEN clients.clientname
		ELSE 'SOLD - ' || clients.clientname END) as clientname
	FROM (AssetsView INNER JOIN ClientAssets ON AssetsView.AssetID = ClientAssets.AssetID)
		INNER JOIN Clients ON Clients.ClientID = ClientAssets.ClientID
	WHERE (AssetsView.singularitem = true) AND (ClientAssets.isissued = true) AND (ClientAssets.isretrived = false)
		AND (AssetsView.lost = false)
	ORDER BY AssetsView.assettypename, AssetsView.assetsubtypename, AssetsView.purchasedate;

--------------------------------- Accounts

CREATE VIEW PeriodView AS
	SELECT Periods.PeriodID, Periods.AccountPeriod, Periods.Startdate, date_part('month', startdate) as monthid,
		to_char(Periods.startdate, 'YYYY') as periodyear, to_char(Periods.startdate, 'Month') as periodmonth,
		(trunc((date_part('month', startdate)-1)/3)+1) as quarter, (trunc((date_part('month', startdate)-1)/6)+1) as semister, 
		getPrevPeriod(Periods.Startdate) as PrevPeriod,
		Periods.NASRate, Periods.CANCRates, Periods.TPRate, Periods.TARAte, Periods.IncentiveRate, 
		Periods.CompetitionCost, Periods.BudgetRate
	FROM Periods
	ORDER BY Periods.Startdate;

CREATE VIEW PeriodYearView AS
	SELECT periodyear
	FROM PeriodView
	GROUP BY periodyear
	ORDER BY periodyear;

CREATE VIEW AccountPeriodView AS
	SELECT AccountPeriod
	FROM PeriodView
	GROUP BY AccountPeriod
	ORDER BY AccountPeriod;

CREATE VIEW PeriodquarterView AS
	SELECT quarter
	FROM PeriodView
	GROUP BY quarter
	ORDER BY quarter;

CREATE VIEW PeriodsemisterView AS
	SELECT semister
	FROM PeriodView
	GROUP BY semister
	ORDER BY semister;

CREATE VIEW PeriodMonthView AS
	SELECT monthid, periodmonth
	FROM PeriodView
	GROUP BY monthid, periodmonth
	ORDER BY monthid, periodmonth;

CREATE VIEW periodassetcostview AS
	SELECT assetsubtypeview.assettypeid, assetsubtypeview.assettypename, assetsubtypeview.assetsubtypeid, assetsubtypeview.assetsubtypename,
		periodview.periodid, periodview.accountperiod, periodview.startdate, periodview.monthid, periodview.periodyear, periodview.periodmonth,
		periodassetcosts.periodassetcostid, periodassetcosts.clientcost, periodassetcosts.segments
	FROM (periodassetcosts INNER JOIN assetsubtypeview ON periodassetcosts.assetsubtypeid = assetsubtypeview.assetsubtypeid)
		INNER JOIN periodview ON periodassetcosts.periodid = periodview.periodid;

CREATE VIEW vw_assets_costing AS
	SELECT clientview.clientgroupid, clientview.clientgroupname, clientview.clientid, clientview.clientname,
		assets.AssetSN, ClientAssets.dateIssued, ClientAssets.dateRetrived, ClientAssets.dateadded, ClientAssets.datechanged, ClientAssets.units,
		assetsubtypeview.assettypeid, assetsubtypeview.assettypename, assetsubtypeview.assetsubtypeid, assetsubtypeview.assetsubtypename,
		periodview.periodid, periodview.accountperiod, periodview.startdate, periodview.monthid, periodview.periodyear, periodview.periodmonth,
		periodassetcosts.periodassetcostid, periodassetcosts.clientcost, periodassetcosts.segments,
		(periodassetcosts.clientcost * ClientAssets.units) as t_clientcost, 
		(periodassetcosts.segments * ClientAssets.units) as t_segments
	FROM (periodassetcosts INNER JOIN assetsubtypeview ON periodassetcosts.assetsubtypeid = assetsubtypeview.assetsubtypeid)
		INNER JOIN Assets ON periodassetcosts.AssetSubTypeID = Assets.AssetSubTypeID
		INNER JOIN periodview ON periodassetcosts.periodid = periodview.periodid
		INNER JOIN ClientAssets ON Assets.Assetid = ClientAssets.Assetid
		INNER JOIN clientview ON ClientAssets.clientid = clientview.clientid
	WHERE (ClientAssets.IsIssued = true) AND (ClientAssets.dateIssued <= periodview.startdate + 14) 
		AND ((ClientAssets.dateRetrived IS NULL) OR (ClientAssets.dateRetrived >= periodview.startdate + 14));

CREATE VIEW vw_assets_changes AS
	SELECT clientview.clientgroupid, clientview.clientgroupname, clientview.clientid, clientview.clientname,
		assets.AssetSN, ClientAssets.dateIssued, ClientAssets.dateRetrived, ClientAssets.dateadded, ClientAssets.datechanged,
		assetsubtypeview.assettypeid, assetsubtypeview.assettypename, assetsubtypeview.assetsubtypeid, assetsubtypeview.assetsubtypename,
		periodview.periodid, periodview.accountperiod, periodview.startdate, periodview.monthid, periodview.periodyear, periodview.periodmonth,
		periodassetcosts.periodassetcostid, periodassetcosts.clientcost, periodassetcosts.segments,
		(periodassetcosts.clientcost * ClientAssets.units) as t_clientcost, 
		(periodassetcosts.segments * ClientAssets.units) as t_segments
	FROM (periodassetcosts INNER JOIN assetsubtypeview ON periodassetcosts.assetsubtypeid = assetsubtypeview.assetsubtypeid)
		INNER JOIN Assets ON periodassetcosts.AssetSubTypeID = Assets.AssetSubTypeID
		INNER JOIN periodview ON periodassetcosts.periodid = periodview.periodid
		INNER JOIN ClientAssets ON Assets.Assetid = ClientAssets.Assetid
		INNER JOIN clientview ON ClientAssets.clientid = clientview.clientid
	WHERE (ClientAssets.IsIssued = true) AND (ClientAssets.dateadded <= periodview.startdate + 14) 
		AND ((ClientAssets.datechanged IS NULL) OR (ClientAssets.datechanged >= periodview.startdate + 14));

CREATE VIEW MIDTTransactionView AS
	SELECT periodview.periodid, periodview.accountperiod, periodview.startdate, periodview.monthid, periodview.periodyear, periodview.periodmonth, periodview.quarter, 
		clients.clientid, clients.clientname, midttransactions.midttransactionid, midttransactions.crs, midttransactions.pcc, midttransactions.agency, midttransactions.prd
	FROM (midttransactions INNER JOIN periodview ON midttransactions.periodid = periodview.periodid)
		LEFT JOIN clients ON midttransactions.clientid = clients.clientid;

CREATE VIEW CompetitionView AS
	SELECT periodview.periodid, periodview.accountperiod, periodview.startdate, periodview.monthid, periodview.periodyear, periodview.periodmonth, periodview.quarter, 
		midttransactions.crs, sum(midttransactions.prd) as sumprd
	FROM (midttransactions INNER JOIN periodview ON midttransactions.periodid = periodview.periodid)
	GROUP BY periodview.periodid, periodview.accountperiod, periodview.startdate, periodview.monthid, periodview.periodyear, periodview.periodmonth, periodview.quarter, 
		midttransactions.crs;

CREATE VIEW TransClientView AS
	SELECT ClientAffiliates.ClientAffiliateID, ClientAffiliates.ClientAffiliateName, ClientGroups.ClientGroupID, ClientGroups.ClientGroupName,
		entitys.entity_id, entitys.entity_name, Clients.ClientID, Clients.ClientName, 
		Clients.TelNo, Clients.Address, Clients.ZipCode, Clients.Town, Clients.Country, Clients.IsIATA
	FROM ClientAffiliates INNER JOIN ClientGroups ON ClientAffiliates.ClientAffiliateID = ClientGroups.ClientAffiliateID
		INNER JOIN Clients ON ClientGroups.ClientGroupID = Clients.ClientGroupID
		INNER JOIN entitys ON Clients.entity_id = entitys.entity_id;

CREATE VIEW TransactionView AS
	SELECT TransClientView.ClientAffiliateID, TransClientView.ClientAffiliateName, TransClientView.ClientGroupID, TransClientView.ClientGroupName,
		TransClientView.entity_id, TransClientView.entity_name, TransClientView.ClientID, TransClientView.ClientName, TransClientView.IsIATA, 
		TransClientView.TelNo, TransClientView.Address, TransClientView.ZipCode, TransClientView.Town, TransClientView.Country,				
		PeriodView.PeriodID, PeriodView.AccountPeriod, PeriodView.Startdate, PeriodView.monthid, PeriodView.periodyear,
		PeriodView.periodmonth, PeriodView.quarter, PeriodView.semister, PeriodView.PrevPeriod, PeriodView.BudgetRate,
		PeriodView.NASRate, PeriodView.CANCRates, PeriodView.TPRate, PeriodView.TARate, PeriodView.IncentiveRate, PeriodView.CompetitionCost,
		Transactions.TransactionID, Transactions.PCC, 
		getsegs(Transactions.clientid, Transactions.periodid, 'M') as AmadeousSegs, 
		getsegs(Transactions.clientid, Transactions.periodid, 'W') as WorldSpanSegs,
		Transactions.NASegs, Transactions.NPSegs, Transactions.NFASegs, Transactions.NBBSegs, Transactions.NRSegs,
		Transactions.BCT, Transactions.AOTSegs, Transactions.PTSegs, Transactions.Narrative, 
		Transactions.eticket, Transactions.pticket, (Transactions.eticket + Transactions.pticket) as tickets,
		getClientCost(TransClientView.ClientID, PeriodView.PeriodID, PeriodView.Startdate) as clientcost,
		getClientCPU(TransClientView.ClientID, PeriodView.Startdate) as clientcpus,
		getPrevSegs(Transactions.Clientid, PeriodView.PrevPeriod) as prevsegs
	FROM (TransClientView INNER JOIN Transactions ON TransClientView.ClientID = Transactions.ClientID)
		INNER JOIN PeriodView ON Transactions.PeriodID = PeriodView.PeriodID
	ORDER BY PeriodView.Startdate;

CREATE VIEW ClientCostView AS
	SELECT ClientAffiliateID, ClientAffiliateName, ClientGroupID, ClientGroupName, ClientID, ClientName, entity_id, entity_name,
		TelNo, Address, ZipCode, Town, Country, IsIATA, 
		PeriodID, AccountPeriod, Startdate, monthid, periodyear, periodmonth, quarter, semister, PrevPeriod, BudgetRate,
		IncentiveRate, CompetitionCost, prevsegs, (prevsegs * (100 + BudgetRate) / 100) as budgetsegs,
		TransactionID, AmadeousSegs, WorldSpanSegs, NASegs, clientcost, clientcpus,
		(NASegs - clientcost) as clientbalance,		
		(CASE WHEN clientcpus = 0 THEN 0 ELSE (NASegs / clientcpus) END) as spc,
		(CASE WHEN clientcost = 0 THEN 100 ELSE 100 * ((NASegs - clientcost) / clientcost) END) as pbalance,
		(CASE WHEN (AmadeousSegs + NASegs) = 0 THEN 0 ELSE (100 * AmadeousSegs / (AmadeousSegs + NASegs)) END) as compratio
	FROM TransactionView;

CREATE VIEW ClientQuarterView AS
	SELECT ClientAffiliateID, ClientAffiliateName, ClientGroupID, ClientGroupName, ClientID, ClientName,
		entity_id, entity_name, periodyear, quarter, semister, 
		sum(AmadeousSegs) as SumAmadeousSegs, Sum(WorldSpanSegs) as SumWorldSpanSegs, Sum(NASegs) as SumNASegs,
		sum(clientcost) as sumclientcost, sum(NASegs - clientcost) as sumclientbalance, 
		(CASE WHEN SUM(clientcost) = 0 THEN 100 ELSE 100 * (sum(NASegs - clientcost) / sum(clientcost)) END) as pbalance,
		(CASE WHEN (SUM(AmadeousSegs) + sum(NASegs)) = 0 THEN 0 ELSE (100 * SUM(AmadeousSegs) / (SUM(AmadeousSegs) + sum(NASegs))) END) as compratio
	FROM TransactionView
	GROUP BY ClientAffiliateID, ClientAffiliateName, ClientGroupID, ClientGroupName, ClientID, ClientName,
		entity_id, entity_name, periodyear, quarter, semister;

CREATE VIEW ClientSemisterView AS
	SELECT ClientAffiliateID, ClientAffiliateName, ClientGroupID, ClientGroupName, ClientID, ClientName,
		entity_id, entity_name, periodyear, semister, 
		sum(AmadeousSegs) as SumAmadeousSegs, Sum(WorldSpanSegs) as SumWorldSpanSegs, Sum(NASegs) as SumNASegs,
		sum(clientcost) as sumclientcost, sum(NASegs - clientcost) as sumclientbalance, 
		(CASE WHEN SUM(clientcost) = 0 THEN 100 ELSE 100 *(sum(NASegs - clientcost) / sum(clientcost)) END) as pbalance,
		(CASE WHEN (SUM(AmadeousSegs) + sum(NASegs)) = 0 THEN 0 ELSE (100 * SUM(AmadeousSegs) / (SUM(AmadeousSegs) + sum(NASegs))) END) as compratio
	FROM TransactionView
	GROUP BY ClientAffiliateID, ClientAffiliateName, ClientGroupID, ClientGroupName, ClientID, ClientName,
		entity_id, entity_name, periodyear, semister;

CREATE VIEW ClientYearView AS
	SELECT ClientAffiliateID, ClientAffiliateName, ClientGroupID, ClientGroupName, ClientID, ClientName,
		entity_id, entity_name, periodyear, 
		sum(AmadeousSegs) as SumAmadeousSegs, Sum(WorldSpanSegs) as SumWorldSpanSegs, Sum(NASegs) as sumNASegs,
		sum(clientcost) as sumclientcost, sum(NASegs - clientcost) as sumclientbalance, 
		(CASE WHEN SUM(clientcost)=0 THEN 100 ELSE 100 *(sum(NASegs - clientcost) / sum(clientcost)) END) as pbalance,
		(CASE WHEN (SUM(AmadeousSegs) + sum(NASegs)) = 0 THEN 0 ELSE (100 * SUM(AmadeousSegs) / (SUM(AmadeousSegs) + sum(NASegs))) END) as compratio
	FROM TransactionView
	GROUP BY ClientAffiliateID, ClientAffiliateName, ClientGroupID, ClientGroupName, ClientID, ClientName,
		entity_id, entity_name, periodyear;

CREATE VIEW ClientAccYearView AS
	SELECT ClientAffiliateID, ClientAffiliateName, ClientGroupID, ClientGroupName, ClientID, ClientName,
		entity_id, entity_name, AccountPeriod, 
		sum(AmadeousSegs) as SumAmadeousSegs, Sum(WorldSpanSegs) as SumWorldSpanSegs, Sum(NASegs) as sumNASegs,
		sum(clientcost) as sumclientcost, sum(NASegs - clientcost) as sumclientbalance, 
		(CASE WHEN SUM(clientcost) = 0 THEN 100 ELSE 100 *(sum(NASegs - clientcost) / sum(clientcost)) END) as pbalance,
		(CASE WHEN (SUM(AmadeousSegs) + sum(NASegs)) = 0 THEN 0 ELSE (100 * SUM(AmadeousSegs) / (SUM(AmadeousSegs) + sum(NASegs))) END) as compratio
	FROM TransactionView
	GROUP BY ClientAffiliateID, ClientAffiliateName, ClientGroupID, ClientGroupName, ClientID, ClientName,
		entity_id, entity_name, AccountPeriod;

CREATE VIEW GroupCostView AS
	(SELECT entity_name, ClientID, ClientName, PeriodID, AccountPeriod, Startdate, monthid, periodyear, periodmonth, quarter, semister,
		IncentiveRate, CompetitionCost,	AmadeousSegs, WorldSpanSegs, NASegs, 
		clientcost, (NASegs - clientcost) as clientbalance, clientcpus,
		(CASE WHEN clientcost = 0 THEN 100 ELSE 100 *((NASegs - clientcost) / clientcost) END) as pbalance,
		(CASE WHEN (AmadeousSegs + NASegs) = 0 THEN 0 ELSE (100 * AmadeousSegs / (AmadeousSegs + NASegs)) END) as compratio
	FROM TransactionView
	WHERE (ClientGroupID=0))
	UNION
	(SELECT entity_name, ClientGroupID, ClientGroupName, PeriodID, AccountPeriod, Startdate, monthid, periodyear, periodmonth, quarter, semister,
		IncentiveRate, CompetitionCost,
		sum(AmadeousSegs) as AmadeousSegs, sum(WorldSpanSegs) as WorldSpanSegs, sum(NASegs) as NASegs,
		sum(clientcost) as clientcost, sum(NASegs - clientcost) as clientbalance, sum(clientcpus) as clientcpus,
		(CASE WHEN SUM(clientcost)=0 THEN 100 ELSE 100 *(sum((NASegs - clientcost)) / sum(clientcost)) END) as pbalance,
		(CASE WHEN SUM(AmadeousSegs + NASegs) = 0 THEN 0 ELSE 100 * SUM(AmadeousSegs) / SUM(AmadeousSegs + NASegs) END) as compratio
	FROM TransactionView
	WHERE (ClientGroupID<>0)
	GROUP BY entity_name, ClientGroupID, ClientGroupName, PeriodID, AccountPeriod, Startdate, monthid, periodyear, periodmonth, quarter, semister, IncentiveRate, CompetitionCost);

CREATE VIEW vw_accmanagersegs AS
	(SELECT entity_name, ClientID, ClientName, PeriodID, AccountPeriod, Startdate, monthid, periodyear, periodmonth, quarter, semister,
		IncentiveRate, CompetitionCost,	AmadeousSegs, WorldSpanSegs, NASegs, 
		clientcost, (NASegs - clientcost) as clientbalance, clientcpus,
		(CASE WHEN clientcost = 0 THEN 100 ELSE 100 *((NASegs - clientcost) / clientcost) END) as pbalance,
		(CASE WHEN (AmadeousSegs + NASegs) = 0 THEN 0 ELSE (100 * AmadeousSegs / (AmadeousSegs + NASegs)) END) as compratio
	FROM TransactionView
	WHERE (ClientGroupID=0))
	UNION
	(SELECT entity_name, ClientGroupID, ClientGroupName, PeriodID, AccountPeriod, Startdate, monthid, periodyear, periodmonth, quarter, semister,
		IncentiveRate, CompetitionCost,
		sum(AmadeousSegs) as AmadeousSegs, sum(WorldSpanSegs) as WorldSpanSegs, sum(NASegs) as NASegs,
		sum(clientcost) as clientcost, sum(NASegs - clientcost) as clientbalance, sum(clientcpus) as clientcpus,
		(CASE WHEN SUM(clientcost)=0 THEN 100 ELSE 100 *(sum((NASegs - clientcost)) / sum(clientcost)) END) as pbalance,
		(CASE WHEN SUM(AmadeousSegs + NASegs) = 0 THEN 0 ELSE 100 * SUM(AmadeousSegs) / SUM(AmadeousSegs + NASegs) END) as compratio
	FROM TransactionView
	WHERE (ClientGroupID<>0)
	GROUP BY entity_name, ClientGroupID, ClientGroupName, PeriodID, AccountPeriod, Startdate, monthid, periodyear, periodmonth, quarter, semister, IncentiveRate, CompetitionCost);

CREATE VIEW GroupQuarterView AS
	SELECT ClientID, ClientName, periodyear, quarter, semister, 
		sum(AmadeousSegs) as SumAmadeousSegs, Sum(WorldSpanSegs) as SumWorldSpanSegs, Sum(NASegs) as SumNASegs,
		sum(clientcost) as sumclientcost, sum(NASegs - clientcost) as sumclientbalance, 
		(CASE WHEN SUM(clientcost)=0 THEN 100 ELSE 100 *(sum(NASegs - clientcost) / sum(clientcost)) END) as pbalance,
		(CASE WHEN (SUM(AmadeousSegs) + sum(NASegs)) = 0 THEN 0 ELSE (100 * SUM(AmadeousSegs) / (SUM(AmadeousSegs) + sum(NASegs))) END) as compratio
	FROM GroupCostView
	GROUP BY ClientID, ClientName, periodyear, quarter, semister;

CREATE VIEW GroupSemisterView AS
	SELECT ClientID, ClientName, periodyear, semister, 
		sum(AmadeousSegs) as SumAmadeousSegs, Sum(WorldSpanSegs) as SumWorldSpanSegs, Sum(NASegs) as SumNASegs,
		sum(clientcost) as sumclientcost, sum(NASegs - clientcost) as sumclientbalance, 
		(CASE WHEN SUM(clientcost)=0 THEN 100 ELSE 100 *(sum(NASegs - clientcost) / sum(clientcost)) END) as pbalance,
		(CASE WHEN (SUM(AmadeousSegs) + sum(NASegs)) = 0 THEN 0 ELSE (100 * SUM(AmadeousSegs) / (SUM(AmadeousSegs) + sum(NASegs))) END) as compratio
	FROM GroupCostView
	GROUP BY ClientID, ClientName, periodyear, semister;

CREATE VIEW GroupYearView AS
	SELECT ClientID, ClientName, periodyear, 
		sum(AmadeousSegs) as SumAmadeousSegs, Sum(WorldSpanSegs) as SumWorldSpanSegs, Sum(NASegs) as sumNASegs,
		sum(clientcost) as sumclientcost, sum(NASegs - clientcost) as sumclientbalance,
		(CASE WHEN SUM(clientcost)=0 THEN 100 ELSE 100 *(sum(NASegs - clientcost) / sum(clientcost)) END) as pbalance,
		(CASE WHEN (SUM(AmadeousSegs) + sum(NASegs)) = 0 THEN 0 ELSE (100 * SUM(AmadeousSegs) / (SUM(AmadeousSegs) + sum(NASegs))) END) as compratio
	FROM GroupCostView
	GROUP BY ClientID, ClientName, periodyear;

CREATE VIEW GroupsCostView AS
	SELECT ClientGroupID, ClientGroupName, PeriodID, AccountPeriod, Startdate, monthid, periodyear, periodmonth, quarter, semister,
		sum(AmadeousSegs) as AmadeousSegs, sum(WorldSpanSegs) as WorldSpanSegs, sum(NASegs) as NASegs,
		sum(clientcost) as clientcost, sum(NASegs - clientcost) as clientbalance, 
		(CASE WHEN SUM(clientcost)=0 THEN 100 ELSE 100 *(sum((NASegs - clientcost)) / sum(clientcost)) END) as pbalance,
		(CASE WHEN (SUM(AmadeousSegs) + sum(NASegs)) = 0 THEN 0
			WHEN SUM(AmadeousSegs) < 0 THEN 0
			ELSE (100 * SUM(AmadeousSegs) / (SUM(AmadeousSegs) + sum(NASegs))) END) as compratio
	FROM TransactionView
	WHERE (ClientGroupID<>0)
	GROUP BY ClientGroupID, ClientGroupName, PeriodID, AccountPeriod, Startdate, monthid, periodyear, periodmonth, quarter, semister;

CREATE VIEW AffiliateCostView AS
	SELECT ClientAffiliateID, ClientAffiliateName, PeriodID, AccountPeriod, Startdate, monthid, periodyear, periodmonth, quarter, semister,
		sum(AmadeousSegs) as AmadeousSegs, sum(WorldSpanSegs) as WorldSpanSegs, sum(NASegs) as NASegs,
		sum(clientcost) as clientcost, sum(NASegs - clientcost) as clientbalance, 
		(CASE WHEN SUM(clientcost) = 0 THEN 100 
			WHEN SUM(AmadeousSegs) < 0 THEN 0
			ELSE 100 *(sum(NASegs - clientcost) / sum(clientcost)) END) as pbalance,
		(CASE WHEN (SUM(AmadeousSegs) + sum(NASegs)) = 0 THEN 0 ELSE (100 * SUM(AmadeousSegs) / (SUM(AmadeousSegs) + sum(NASegs))) END) as compratio
	FROM TransactionView	
	GROUP BY ClientAffiliateID, ClientAffiliateName, PeriodID, AccountPeriod, Startdate, monthid, periodyear, periodmonth, quarter, semister;  

CREATE VIEW ConsultantTransactionView AS
	SELECT Clients.ClientID, Clients.ClientName, ConsultantTransactions.ConsultantTransactionID, ConsultantTransactions.PeriodID, 
		ConsultantTransactions.PCC,	ConsultantTransactions.SON,	ConsultantTransactions.prd1, ConsultantTransactions.prd2, 
		ConsultantTransactions.prd3, ConsultantTransactions.modprod, ConsultantTransactions.target,
		ConsultantTransactions.Narrative
	FROM Clients INNER JOIN ConsultantTransactions ON Clients.ClientID = ConsultantTransactions.ClientID
	ORDER BY ConsultantTransactions.prd3 DESC;

CREATE VIEW QuarterTransView AS
	(SELECT ClientID, ClientName, AccountPeriod, periodyear, quarter, 
		sum(AmadeousSegs) as AmadeousSegs, sum(WorldSpanSegs) as WorldSpanSegs, sum(NASegs) as NASegs,
		sum(clientcost) as clientcost, sum(NASegs - clientcost) as clientbalance, 
		(CASE WHEN SUM(clientcost) = 0 THEN 100 ELSE 100 *(sum(NASegs - clientcost) / sum(clientcost)) END) as pbalance,
		(100 * SUM(AmadeousSegs) / (SUM(AmadeousSegs) + sum(NASegs))) as compratio,
		sum((NASegs - clientcost) * IncentiveRate) as incentives
	FROM TransactionView
	WHERE (ClientGroupID=0)
	GROUP BY ClientID, ClientName, AccountPeriod, periodyear, quarter)
	UNION
	(SELECT ClientAffiliateID, ClientAffiliateName, AccountPeriod, periodyear, quarter, 
		sum(AmadeousSegs) as AmadeousSegs, sum(WorldSpanSegs) as WorldSpanSegs, sum(NASegs) as NASegs,
		sum(clientcost) as clientcost, sum(NASegs - clientcost) as clientbalance, 
		(CASE WHEN SUM(clientcost) = 0 THEN 100 ELSE 100 *(sum(NASegs - clientcost) / sum(clientcost)) END) as pbalance,
		(100 * SUM(AmadeousSegs) / (SUM(AmadeousSegs) + sum(NASegs))) as compratio,
		sum((NASegs - clientcost) * IncentiveRate) as incentives
	FROM TransactionView
	WHERE (ClientAffiliateID <> 0)	
	GROUP BY ClientAffiliateID, ClientAffiliateName, AccountPeriod, periodyear, quarter)
	UNION
	(SELECT ClientGroupID, ClientGroupName, AccountPeriod, periodyear, quarter, 
		sum(AmadeousSegs) as AmadeousSegs, sum(WorldSpanSegs) as WorldSpanSegs, sum(NASegs) as NASegs,
		sum(clientcost) as clientcost, sum(NASegs - clientcost) as clientbalance, 
		(CASE WHEN SUM(clientcost) = 0 THEN 100 ELSE 100 *(sum(NASegs - clientcost) / sum(clientcost)) END) as pbalance,
		(100 * SUM(AmadeousSegs) / (SUM(AmadeousSegs) + sum(NASegs))) as compratio,
		sum((NASegs - clientcost) * IncentiveRate) as incentives
	FROM TransactionView
	WHERE (ClientGroupID <> 0) AND (ClientAffiliateID = 0)
	GROUP BY ClientGroupID, ClientGroupName, AccountPeriod, periodyear, quarter);  

CREATE VIEW AllTransView AS
	(SELECT ClientID, ClientName, AccountPeriod,
		sum(AmadeousSegs) as AmadeousSegs, sum(WorldSpanSegs) as WorldSpanSegs, sum(NASegs) as NASegs,
		sum(clientcost) as clientcost, sum(NASegs - clientcost) as clientbalance, 
		(CASE WHEN SUM(clientcost) = 0 THEN 100 ELSE 100 *(sum(NASegs - clientcost) / sum(clientcost)) END) as pbalance,
		(100 * SUM(AmadeousSegs) / (SUM(AmadeousSegs) + sum(NASegs))) as compratio,
		sum((NASegs - clientcost) * IncentiveRate) as incentives
	FROM TransactionView
	WHERE (ClientGroupID=0)
	GROUP BY ClientID, ClientName, AccountPeriod)
	UNION
	(SELECT ClientAffiliateID, ClientAffiliateName, AccountPeriod,
		sum(AmadeousSegs) as AmadeousSegs, sum(WorldSpanSegs) as WorldSpanSegs, sum(NASegs) as NASegs,
		sum(clientcost) as clientcost, sum(NASegs - clientcost) as clientbalance, 
		(CASE WHEN SUM(clientcost) = 0 THEN 100 ELSE 100 *(sum(NASegs - clientcost) / sum(clientcost)) END) as pbalance,
		(100 * SUM(AmadeousSegs) / (SUM(AmadeousSegs) + sum(NASegs))) as compratio,
		sum((NASegs - clientcost) * IncentiveRate) as incentives
	FROM TransactionView
	WHERE (ClientAffiliateID <> 0)	
	GROUP BY ClientAffiliateID, ClientAffiliateName, AccountPeriod)
	UNION
	(SELECT ClientGroupID, ClientGroupName, AccountPeriod,
		sum(AmadeousSegs) as AmadeousSegs, sum(WorldSpanSegs) as WorldSpanSegs, sum(NASegs) as NASegs,
		sum(clientcost) as clientcost, sum(NASegs - clientcost) as clientbalance, 
		(CASE WHEN SUM(clientcost) = 0 THEN 100 ELSE 100 *(sum(NASegs - clientcost) / sum(clientcost)) END) as pbalance,
		(100 * SUM(AmadeousSegs) / (SUM(AmadeousSegs) + sum(NASegs))) as compratio,
		sum((NASegs - clientcost) * IncentiveRate) as incentives
	FROM TransactionView
	WHERE (ClientGroupID <> 0) AND (ClientAffiliateID = 0)
	GROUP BY ClientGroupID, ClientGroupName, AccountPeriod);  

CREATE VIEW consdistributionview AS
	SELECT clientview.clientgroupid, clientview.clientgroupname, clientview.clientid, clientview.clientname, 
		consultanttransactions.consultanttransactionid, consultanttransactions.pcc, consultanttransactions.son, 
		consultanttransactions.prd3, consultanttransactions.periodid, 
		getdistribution(consultanttransactions.consultanttransactionid) AS distribution, 
		gettkpdistribution(consultanttransactions.consultanttransactionid) AS tkpdistribution
	FROM clientview INNER JOIN consultanttransactions ON clientview.clientid = consultanttransactions.clientid
	ORDER BY clientview.clientid;

CREATE VIEW totalproductivityview AS 
	SELECT periods.periodid, periods.startdate, sum(transactions.nasegs) AS segments, 
		sum(getClientCost(transactions.ClientID, Periods.PeriodID, Periods.Startdate)) AS cost,
		sum(transactions.nasegs - getClientCost(transactions.ClientID, Periods.PeriodID, Periods.Startdate)) AS balance
	FROM periods INNER JOIN transactions ON periods.periodid = transactions.periodid
	GROUP BY periods.periodid, periods.startdate 
	ORDER BY periods.startdate;

CREATE VIEW vw_contracts AS
	SELECT incentive_types.incentive_type_id, incentive_types.incentive_type_name, 
		ClientGroups.ClientGroupID, ClientGroups.ClientGroupName, clients.clientid, clients.clientname,
		contracts.contract_id, contracts.after_cost, contracts.market_share,
		contracts.business_volume, contracts.contract_date, contracts.contract_end,
		contracts.details
	FROM ((incentive_types INNER JOIN contracts ON incentive_types.incentive_type_id = contracts.incentive_type_id)
		LEFT JOIN ClientGroups ON contracts.ClientGroupID = ClientGroups.ClientGroupID)
		LEFT JOIN clients ON contracts.clientid = clients.clientid;

CREATE VIEW daylistview AS
	SELECT dailytransactions.prddate
	FROM dailytransactions
	GROUP BY dailytransactions.prddate
	ORDER BY dailytransactions.prddate;

CREATE VIEW dailytransactionview AS
SELECT clientview.clientaffiliateid, clientview.clientaffiliatename, clientview.clientgroupid, clientview.clientgroupname,
	clientview.entity_id, clientview.entity_name, clientview.clientid, clientview.clientname, dailytransactions.dailytransactionid,
	dailytransactions.prddate, dailytransactions.pcc, dailytransactions.dailynetsegments, dailytransactions.mtdnetsegments,
	dailytransactions.ytdnetsegments, getClientCost(clientview.clientid) as clientcost
FROM dailytransactions INNER JOIN clientview ON dailytransactions.clientid = clientview.clientid;

------------------------------------------------- Training
CREATE VIEW TrainingView AS
	SELECT entitys.entity_name, Training.TrainingID, Training.entity_id, Training.TrainingTypeID, Training.StartDate, 
		Training.StopDate, Training.IsDone, Training.Amount, TrainingTypes.TrainingTypeName
	FROM Training INNER JOIN TrainingTypes ON Training.TrainingTypeID = TrainingTypes.TrainingTypeID
		INNER JOIN entitys ON Training.entity_id = entitys.entity_id;;

CREATE VIEW ClientTrainingView AS
	SELECT ConsultantView.ClientID, ConsultantView.ClientName, ConsultantView.consultantid, ConsultantView.consultantname, 
		ClientTraining.ClientTrainingID, ClientTraining.TrainingID,	ClientTraining.IsDone,
		ClientTraining.IsPaid, ClientTraining.IsCert, ClientTraining.IsCompleted, ClientTraining.Marks
	FROM ConsultantView INNER JOIN ClientTraining ON ConsultantView.ConsultantID = ClientTraining.ConsultantID;

CREATE VIEW ConsultantTrainingView AS
	SELECT TrainingView.entity_name, TrainingView.TrainingTypeName, TrainingView.TrainingID, TrainingView.entity_id,
		TrainingView.TrainingTypeID,
		TrainingView.StartDate, TrainingView.StopDate, TrainingView.IsDone as trainingdone, TrainingView.Amount,
		ClientTrainingView.ClientID, ClientTrainingView.ClientName, ClientTrainingView.consultantid, ClientTrainingView.consultantname, 
		ClientTrainingView.ClientTrainingID, ClientTrainingView.IsDone,
		ClientTrainingView.IsPaid, ClientTrainingView.IsCert, ClientTrainingView.IsCompleted, ClientTrainingView.Marks
	FROM TrainingView INNER JOIN ClientTrainingView ON TrainingView.TrainingID = ClientTrainingView.TrainingID;


--------------------------------------------------- Charity Additions

CREATE VIEW vw_transaction_cg AS
	SELECT TransClientView.ClientAffiliateID, TransClientView.ClientAffiliateName, TransClientView.ClientGroupID, TransClientView.ClientGroupName,
		TransClientView.entity_id, TransClientView.entity_name, TransClientView.ClientID, TransClientView.ClientName, TransClientView.IsIATA, 
		TransClientView.TelNo, TransClientView.Address, TransClientView.ZipCode, TransClientView.Town, TransClientView.Country,				
		PeriodView.PeriodID, PeriodView.AccountPeriod, PeriodView.Startdate, PeriodView.monthid, PeriodView.periodyear,
		PeriodView.periodmonth, PeriodView.quarter, PeriodView.semister, PeriodView.PrevPeriod, PeriodView.BudgetRate,
		PeriodView.NASRate, PeriodView.CANCRates, PeriodView.TPRate, PeriodView.TARate, PeriodView.IncentiveRate, PeriodView.CompetitionCost,
		Transactions.TransactionID, Transactions.PCC, 
		getsegs(Transactions.clientid, Transactions.periodid, 'M') as AmadeousSegs, getsegs(Transactions.clientid, Transactions.periodid, 'W') as WorldSpanSegs,
		Transactions.NASegs, Transactions.NPSegs, Transactions.NFASegs, Transactions.NBBSegs, Transactions.NRSegs,
		Transactions.BCT, Transactions.AOTSegs, Transactions.PTSegs, Transactions.productivity, Transactions.Narrative, 
		Transactions.eticket, Transactions.pticket, (Transactions.eticket + Transactions.pticket) as tickets,
		getClientCost(TransClientView.ClientID, PeriodView.PeriodID, PeriodView.Startdate) as clientcost,
		getClientCPU(TransClientView.ClientID, PeriodView.Startdate) as clientcpus,
		getPrevSegs(Transactions.Clientid, PeriodView.PrevPeriod) as prevsegs
	FROM (TransClientView INNER JOIN Transactions ON TransClientView.ClientID = Transactions.ClientID)
		INNER JOIN PeriodView ON Transactions.PeriodID = PeriodView.PeriodID
	ORDER BY PeriodView.Startdate;

CREATE VIEW vw_clientcost_cg AS
	SELECT ClientAffiliateID, ClientAffiliateName, ClientGroupID, ClientGroupName, ClientID, ClientName, entity_id, entity_name,
		TelNo, Address, ZipCode, Town, Country, IsIATA, 
		PeriodID, AccountPeriod, Startdate, monthid, periodyear, periodmonth, quarter, semister, PrevPeriod, BudgetRate,
		IncentiveRate, CompetitionCost, prevsegs, (prevsegs * (100 + BudgetRate) / 100) as budgetsegs,
		TransactionID, AmadeousSegs, WorldSpanSegs, NASegs, productivity, clientcost, clientcpus,
		(NASegs - clientcost) as clientbalance,		
		(CASE WHEN clientcpus = 0 THEN 0 ELSE (NASegs / clientcpus) END) as spc,
		(CASE WHEN clientcost = 0 THEN 100 ELSE 100 * ((NASegs - clientcost) / clientcost) END) as pbalance,
		(CASE WHEN (AmadeousSegs + NASegs) = 0 THEN 0 ELSE (100 * AmadeousSegs / (AmadeousSegs + NASegs)) END) as compratio
	FROM vw_transaction_cg;

CREATE VIEW vw_groupcost_cg AS
	(SELECT ClientID, ClientName, PeriodID, AccountPeriod, Startdate, monthid, periodyear, periodmonth, quarter, semister,
		IncentiveRate, CompetitionCost,	productivity, AmadeousSegs, WorldSpanSegs, NASegs, 
		clientcost, (NASegs - clientcost) as clientbalance, clientcpus,
		(CASE WHEN clientcost = 0 THEN 100 ELSE 100 *((NASegs - clientcost) / clientcost) END) as pbalance,
		(CASE WHEN (AmadeousSegs + NASegs) = 0 THEN 0 ELSE (100 * AmadeousSegs / (AmadeousSegs + NASegs)) END) as compratio
	FROM vw_transaction_cg
	WHERE (ClientGroupID=0))
	UNION
	(SELECT ClientGroupID, ClientGroupName, PeriodID, AccountPeriod, Startdate, monthid, periodyear, periodmonth, quarter, semister,
		IncentiveRate, CompetitionCost, sum(productivity) as productivity,
		sum(AmadeousSegs) as AmadeousSegs, sum(WorldSpanSegs) as WorldSpanSegs, sum(NASegs) as NASegs,
		sum(clientcost) as clientcost, sum(NASegs - clientcost) as clientbalance, sum(clientcpus) as clientcpus,
		(CASE WHEN SUM(clientcost)=0 THEN 100 ELSE 100 *(sum((NASegs - clientcost)) / sum(clientcost)) END) as pbalance,
		(CASE WHEN SUM(AmadeousSegs + NASegs) = 0 THEN 0 ELSE 100 * SUM(AmadeousSegs) / SUM(AmadeousSegs + NASegs) END) as compratio
	FROM vw_transaction_cg
	WHERE (ClientGroupID<>0)
	GROUP BY ClientGroupID, ClientGroupName, PeriodID, AccountPeriod, Startdate, monthid, periodyear, periodmonth, quarter, semister, IncentiveRate, CompetitionCost);

CREATE VIEW vw_midt_summary AS
	SELECT t_trans.periodid, t_trans.accountperiod, t_trans.startdate,
		t_trans.periodyear, t_trans.periodmonth, t_trans.t_segs, g_trans.g_segs, m_trans.m_segs,
		(t_trans.t_segs - g_trans.g_segs - m_trans.m_segs) as o_segs,
		100 * (g_trans.g_segs / t_trans.t_segs) as m_share
	FROM 
		(SELECT periods.periodid, periods.accountperiod, periods.startdate,
		to_char(Periods.startdate, 'YYYY') as periodyear, to_char(Periods.startdate, 'Month') as periodmonth,
		sum(MIDTTransactions.prd) as t_segs
		FROM periods INNER JOIN MIDTTransactions ON periods.periodid = MIDTTransactions.periodid
		GROUP BY periods.periodid, periods.accountperiod, periods.startdate,
		to_char(Periods.startdate, 'YYYY'), to_char(Periods.startdate, 'Month')
		ORDER BY periods.startdate) as t_trans
	LEFT JOIN
		(SELECT MIDTTransactions.periodid,  sum(MIDTTransactions.prd) as g_segs
		FROM MIDTTransactions 
		WHERE (MIDTTransactions.crs = 'G')
		GROUP BY MIDTTransactions.periodid) as g_trans
	ON t_trans.periodid = g_trans.periodid
	LEFT JOIN
		(SELECT MIDTTransactions.periodid,  sum(MIDTTransactions.prd) as m_segs 
		FROM MIDTTransactions 
		WHERE (MIDTTransactions.crs = 'M')
		GROUP BY MIDTTransactions.periodid) as m_trans
	ON t_trans.periodid = m_trans.periodid;


--------------------------------------------------
CREATE VIEW vw_consultanttransactions AS
	SELECT clientid, periodid, pcc, sum(prd3) as prod
	FROM consultanttransactions
	GROUP BY clientid, periodid, pcc;

CREATE VIEW vw_group_segments AS
	SELECT clients.clientgroupid, consultanttransactions.periodid, sum(consultanttransactions.prd3) as prod
	FROM consultanttransactions INNER JOIN clients ON consultanttransactions.clientid = clients.clientid
	GROUP BY clients.clientgroupid, consultanttransactions.periodid;


