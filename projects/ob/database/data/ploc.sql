

Insert into C_BPARTNER_LOCATION (C_BPARTNER_LOCATION_ID, C_BPARTNER_ID, C_LOCATION_ID, NAME, PHONE, FAX, AD_CLIENT_ID, AD_ORG_ID, ISACTIVE, CREATED, CREATEDBY, UPDATED, UPDATEDBY, ISBILLTO, ISSHIPTO, ISPAYFROM, ISREMITTO, PHONE2, C_SALESREGION_ID, ISTAXLOCATION, UPC) 
values ('3BFD54D0384341538F9F1595AB91FCFE','E1059BA53AE7467797C1A8381D37B85E','Y',to_date('15-AUG-12','DD-MON-RR'),'100',to_date('15-AUG-12','DD-MON-RR'),'100', 'Y','Y','Y','Y',null,null,'N',null);


Insert Into C_Bpartner_Location (C_Bpartner_Location_Id, C_Bpartner_Id, C_Location_Id, Name, Phone, Fax, Ad_Client_Id, Ad_Org_Id, Isactive, Created, Createdby, Updated, Updatedby, Isbillto, Isshipto, Ispayfrom, Isremitto, Phone2, C_Salesregion_Id, Istaxlocation, Upc) 
Select Get_Uuid(), C_Bpartner.C_Bpartner_Id, C_Location_Id, C_Location.Client_Name, substr(Client_Phone, 1, 39), Client_Fax,
'3BFD54D0384341538F9F1595AB91FCFE','E1059BA53AE7467797C1A8381D37B85E','Y',To_Date('15-AUG-12','DD-MON-RR'),'100',To_Date('15-AUG-12','DD-MON-RR'),'100', 'Y','Y','Y','Y',Null,Null,'N',Null
from C_Location inner join C_BPARTNER on C_Location.Client_Name = C_BPARTNER.name;


