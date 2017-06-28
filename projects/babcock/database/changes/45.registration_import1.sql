CREATE TABLE adm_import1 (
	app_id					integer primary key,
	bussary_code			varchar(50),
	card_number				varchar(50),
	email_address			varchar(50),
	first_password			varchar(50),
	entity_password			varchar(64)
);

DELETE FROM adm_import1;

INSERT INTO adm_import1 (app_id, bussary_code, card_number) VALUES (

ALTER TABLE adm_import1 ADD entity_password varchar(64);
ALTER TABLE registrations ADD entity_password varchar(64);
ALTER TABLE app_students ADD entity_password varchar(64);

UPDATE adm_import1 SET email_address = entitys.user_name, entity_password = entitys.entity_password
FROM entitys WHERE adm_import1.app_id = entitys.entity_id;

existingid = app_id


INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('67542', 'SMAKOL0022', '7079895541845438', '67542@student.babcock.edu.ng', 'CcO2Ob11');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('67291', 'SCHIBL0006', '7079895541778084', '67291@student.babcock.edu.ng', 'CcO2Ob11');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('67241', 'SKEHOL0023', '7079895541834507', '67241@student.babcock.edu.ng', 'CcO2Ob11');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('67538', 'SDAROL0017', '7079895541792192', '67538@student.babcock.edu.ng', 'CcO2Ob11');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('67543', 'SOLOOD0003', '7079895541881029', '67543@student.babcock.edu.ng', 'CcO2Ob11');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('65823', 'SCHILU0001', '7079895541782086', '65823@student.babcock.edu.ng', 'CcO2Ob11');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('67569', 'SAKIAK0070', '7079895541742239', '67569@student.babcock.edu.ng', 'CcO2Ob11');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('67617', 'SKARIS0001', '7079895541822411', '67617@student.babcock.edu.ng', 'CcO2Ob11');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('67623', 'SMUDDA0001', '7079895541861203', '67623@student.babcock.edu.ng', 'CcO2Ob11');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('67061', 'SONIOL0051', '7079895541895706', '67061@student.babcock.edu.ng', 'CcO2Ob11');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('67590', 'SOVICA0001', '7079895541901561', '67590@student.babcock.edu.ng', 'CcO2Ob11');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('67609', 'SNWACH0122', '7079895541764795', '67609@student.babcock.edu.ng', 'CcO2Ob11');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('63044', 'SBENJO0001', '7079895541754119', '63044@student.babcock.edu.ng', 'CcO2Ob11');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('63048', 'SRUTOG0002', '7079895541911123', '63048@student.babcock.edu.ng', 'CcO2Ob11');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('65675', 'SSAROL0003', '7079895541927350', '65675@student.babcock.edu.ng', 'CcO2Ob11');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('67572', 'SAIGNA0001', '7079895541733964', '67572@student.babcock.edu.ng', 'CcO2Ob11');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('67512', 'SOKUGE0001', '7079895541872085', '67512@student.babcock.edu.ng', 'CcO2Ob11');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('67655', 'SUGOVI0002', '7079895541931634', '67655@student.babcock.edu.ng', 'CcO2Ob11');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('67658', 'SADEMA0046', '7079895541855338', '67658@student.babcock.edu.ng', 'CcO2Ob11');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('67657', 'SADESH0011', '7079895541724377', '67657@student.babcock.edu.ng', 'CcO2Ob11');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('67659', 'SHENJU0001', '7079895541819615', '67659@student.babcock.edu.ng', 'CcO2Ob11');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('66974', 'SDOKPA0002', '7079895541807453', '66974@student.babcock.edu.ng', 'CcO2Ob11');


INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('67263', 'SOKEIF0005', '7079895541466847', 'OKEKEARUI@student.babcock.edu.ng', 'CcO2Ob11');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('67376', 'SEMMYU0001', '7079895541249342', 'EMMANUELY@student.babcock.edu.ng', 'Bb221A$O');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('67378', 'SFASOL0049', '7079895541504902', 'OLUWADAMILAREF@student.babcock.edu.ng', '1CBO2KC0');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('67377', 'SARUOL0002', '7079895541484154', 'OLADUNJOYEA@student.babcock.edu.ng', '2AACcO5A');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('67339', 'SOGBIF0005', '7079895541453365', 'OGBOGUI@student.babcock.edu.ng', '52cC0O0O');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('67379', 'SAKIOL0469', '7079895541155812', 'AKINMOLAYANO@student.babcock.edu.ng', 'AA$A1A0A');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('67380', 'SERAEM0001', '7079895541277137', 'ERAKHIFUE@student.babcock.edu.ng', 'KACOB02c');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('67382', 'SAMION0001', '7079895541178046', 'AMIEGBEBHORC@student.babcock.edu.ng', 'b2Cb15B2');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('67390', 'SMASOL0001', '7079895541439554', 'MASANWOO@student.babcock.edu.ng', '$BBBc05A');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('67397', 'SAGUAD0006', '7079895541401505', 'KAOSARAA@student.babcock.edu.ng', '51K5AA$B');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('67398', 'SSULOS0002', '7079895541561290', 'SULEMANO@student.babcock.edu.ng', '111$BbA$');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('67375', 'SALAHA0004', '7079895541166280', 'AKOLADEA@student.babcock.edu.ng', 'O0ABKbb0');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('67400', 'SFAGOG0001', '7079895541286849', 'FAGBEMIO@student.babcock.edu.ng', '2BbO2bKb');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('67336', 'SADEJO0035', '7079895541106039', 'ADEBIYIJ@student.babcock.edu.ng', 'b0bC2$C5');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('67419', 'SODEUG0002', '7079895541441931', 'ODERAU@student.babcock.edu.ng', '$1$51A50');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('67427', 'SIKECH0022', '7079895541321349', 'FRANCESSI@student.babcock.edu.ng', 'BcAC2CKC');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('67426', 'SEMESA0005', '7079895541232165', 'EMEHIS@student.babcock.edu.ng', 'AKA150BC');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('67429', 'SIMOJE0004', '7079895541361246', '@student.babcock.edu.ng', 'OK20250A');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('67413', 'SODUOL0182', '7079895541491621', 'OLASUNKANMIO@student.babcock.edu.ng', 'cC121$2b');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('67373', 'SADEAB0231', '7079895541121327', 'ADEKANBIA@student.babcock.edu.ng', '0A15OOK1');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('67472', 'SIKESA0002', '7079895541199604', 'CHINONYEREMI@student.babcock.edu.ng', '$AO$CbAC');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('67471', 'SOKOED0005', '7079895541477356', 'OKONE@student.babcock.edu.ng', '2BOA511B');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('67435', 'SADEOL0647', '7079895541137968', 'ADEOLAO@student.babcock.edu.ng', 'O1BC1$0K');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('66554', 'SIGHIS0002', '7079895541353656', 'IGHO-ORIENRUC@student.babcock.edu.ng', 'Kb11K22K');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('66988', 'SIGEAK0001', '7079895541345447', 'IGEDIB@student.babcock.edu.ng', 'Kb11K22K');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('67531', 'SWILPA0001', '7079895541549717', 'PAULA-MARYW@student.babcock.edu.ng', '101KKOBB');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('67526', 'SADEAD0728', '7079895541146670', 'ADESHINAA@student.babcock.edu.ng', '2BbKB1A$');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('67469', 'SOKUFA0005', '7079895541303362', 'FAVOURO@student.babcock.edu.ng', 'KK5210O5');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('58982', 'SFEGJA0001', '7079895541313478', 'FEGBEBOHJ@student.babcock.edu.ng', 'OCbC$2C2');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('67502', 'SOSACZ0001', '7079895541528901', 'OSAINC@student.babcock.edu.ng', '2b1b$1Oc');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('67534', 'SENOMO0001', '7079895541256305', 'ENOBONGM@student.babcock.edu.ng', 'c1$AK$5A');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('67588', 'SOPAOL0022', '7079895541513754', 'OPASHOO@student.babcock.edu.ng', '$b$c$100');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('67494', 'SONWJO0003', '7079895541393942', 'JOELO@student.babcock.edu.ng', 'C5C5cCAb');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('67529', 'SJERUG0001', '7079895541378885', 'JERRY-UGWUT@student.babcock.edu.ng', 'OC02C00b');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('67391', 'SOKIUG0001', '7079895541578641', 'UGHOO@student.babcock.edu.ng', 'K11cB5O$');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('67424', 'SANIDI0001', '7079895541189506', 'ANIEFOD@student.babcock.edu.ng', '$1cO22$1');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('67403', 'SADETO0102', '7079895541119602', 'ADEDAYOT@student.babcock.edu.ng', 'Ab1A1O$C');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('67530', 'SEGBKA0001', '7079895541211300', 'EGBEZORU@student.babcock.edu.ng', 'B5BbCBK1');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('67589', 'SRAFMU0001', '7079895541554899', 'RAFIUA@student.babcock.edu.ng', 'K2ACAbCK');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('67431', 'SMARKE0003', '7079895541423442', 'MARKUSU@student.babcock.edu.ng', '$Oc0bbc5');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('67511', 'SOSIOL0053', '7079895541537274', 'OSIYALEO@student.babcock.edu.ng', 'O1b5O51c');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('56783', 'SFALDO0003', '7079895541294025', 'FALOYEA@student.babcock.edu.ng', '5A25b2$2');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('56427', 'SJIDOL0001', '7079895541381277', 'JIDE- ADEWOLEO@student.babcock.edu.ng', 'O152A2K2');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('60543', 'SENWFU0001', '7079895541266254', 'ENWOSEF@student.babcock.edu.ng', 'O152A2K2');


INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('66866', 'SANJES0001', '7079895540597253', 'AnjolaE@student.babcock.edu.ng', 'CcO2Ob11');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('67157', 'SABDMO0001', '7079895540419102', 'AbdulM@student.babcock.edu.ng', 'Bb221A$O');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('67155', 'SIKWMA0001', '7079895540703299', 'MaryI@student.babcock.edu.ng', '1CBO2KC0');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('67121', 'SALAMU0005', '7079895540732348', 'MuhammedA@student.babcock.edu.ng', '2AACcO5A');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('55192', 'SEDIDA0001', '7079895540556465', 'EdimD@student.babcock.edu.ng', '52cC0O0O');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('67161', 'SSENSA0001', '7079895540915729', 'SamuelS@student.babcock.edu.ng', 'AA$A1A0A');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('67156', 'SALAOL0071', '7079895540498734', 'AlakalokoO@student.babcock.edu.ng', 'KACOB02c');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('67117', 'SADEOL0646', '7079895540447533', 'AdegoroyeO@student.babcock.edu.ng', 'b2Cb15B2');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('63207', 'SOSAED0002', '7079895540897661', 'OsakweO@student.babcock.edu.ng', '$BBBc05A');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('58033', 'SNNACH0011', '7079895540757162', 'NnajiD@student.babcock.edu.ng', '51K5AA$B');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('67024', 'SUZOMA0001', '7079895541004283', 'UzoekweM@student.babcock.edu.ng', '111$BbA$');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('67098', 'SOKECA0002', '7079895540822180', 'OkereC@student.babcock.edu.ng', 'O0ABKbb0');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('63125', 'SOKUTH0001', '7079895540847468', 'OkudinaniH@student.babcock.edu.ng', '2BbO2bKb');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('66579', 'SADEAD0727', '7079895540453085', 'AdeyinkaO@student.babcock.edu.ng', 'b0bC2$C5');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('54356', 'SOYEEM0008', '7079895540907080', 'OyetundeO@student.babcock.edu.ng', '$1$51A50');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('59351', 'SOGUJO0013', '7079895540817073', 'OgunsunmiB@student.babcock.edu.ng', 'BcAC2CKC');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('59197', 'SSIKKE0001', '7079895540938978', 'SikiruK@student.babcock.edu.ng', 'AKA150BC');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('57860', 'SMEBTE0001', '7079895540713421', 'MebinueniJ@student.babcock.edu.ng', 'OK20250A');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('66882', 'SFOLOL0033', '7079895540632498', 'FolorunshoM@student.babcock.edu.ng', 'cC121$2b');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('54530', 'SOGUOP0012', '7079895540792433', 'OgunleyeT@student.babcock.edu.ng', '0A15OOK1');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('67169', 'SEMMID0001', '7079895540563727', 'EmmanuelT@student.babcock.edu.ng', '$AO$CbAC');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('66995', 'SAKPCH0006', '7079895540484411', 'AkpunonuS@student.babcock.edu.ng', '2BOA511B');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('59584', 'SIJAOL0004', '7079895540679770', 'IjasanA@student.babcock.edu.ng', 'O1BC1$0K');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('595LA', 'SOGUVI0010', '7079895540805672', 'OgunmoyeV@student.babcock.edu.ng', '2$bcABc2');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('67245', 'SOKWEM0002', '7079895540851007', 'OkworE@student.babcock.edu.ng', 'Kb11K22K');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('65452', 'SSIMAY0001', '7079895540941790', 'SimeonA@student.babcock.edu.ng', 'Kb11K22K');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('67354', 'SAMASA0002', '7079895540503533', 'AmaizeS@student.babcock.edu.ng', '$$1b2OcC');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('67355', 'SNWAFO0001', '7079895540776766', 'NwaniF@student.babcock.edu.ng', 'C2KcK0b$');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('67356', 'SOLUFA0013', '7079895540865908', 'OluwafemiF@student.babcock.edu.ng', '101KKOBB');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('67366', 'SDAVOL0010', '7079895540545096', 'DavidO@student.babcock.edu.ng', '2BbKB1A$');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('67299', 'SUDUIG0001', '7079895540995515', 'UdumaI@student.babcock.edu.ng', 'KK5210O5');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('67298', 'SIDOOL0033', '7079895540665860', 'IdowuO@student.babcock.edu.ng', 'OCbC$2C2');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('67284', 'SLAWFE0001', '7079895540623141', 'FeranmiL@student.babcock.edu.ng', '2b1b$1Oc');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('67246', 'SSOFOL0018', '7079895540955691', 'SofoluweO@student.babcock.edu.ng', 'c1$AK$5A');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('67251', 'SMIRAD0001', '7079895540721309', 'MiracleA@student.babcock.edu.ng', '$b$c$100');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('67286', 'SOLABO0018', '7079895540528878', 'BoluwatifeO@student.babcock.edu.ng', 'C5C5cCAb');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('64595', 'SESSSU0002', '7079895540586553', 'EssienS@student.babcock.edu.ng', 'OC02C00b');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('67328', 'SAYOIF0002', '7079895540512260', 'AyokunmiI@student.babcock.edu.ng', 'K11cB5O$');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('67262', 'SNDUES0001', '7079895540745555', 'NdulueE@student.babcock.edu.ng', '$1cO22$1');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('57639', 'SGBAES0002', '7079895540641598', 'GbahaboC@student.babcock.edu.ng', 'Ab1A1O$C');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('67268', 'SOKOCH0073', '7079895540835778', 'OkoloC@student.babcock.edu.ng', 'B5BbCBK1');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('67282', 'SAGUPR0001', '7079895540467515', 'AguzueP@student.babcock.edu.ng', 'O1b5O51c');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('67294', 'SJOECH0002', '7079895540537325', 'ChinwenduJ@student.babcock.edu.ng', 'K2ACAbCK');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('67137', 'SGINMG0001', '7079895540653569', 'GinikachiM@student.babcock.edu.ng', '$Oc0bbc5');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('67300', 'SAGHET0001', '7079895540984907', 'TessyA@student.babcock.edu.ng', 'O1b5O51c');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('673MC', 'SNWACH0121', '7079895540761792', 'NwabichiriC@student.babcock.edu.ng', '5A25b2$2');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('67360', 'SSANTE0003', '7079895540926379', 'SangodeyiT@student.babcock.edu.ng', 'O152A2K2');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('67362', 'SOBIOL0012', '7079895540782418', 'ObiO@student.babcock.edu.ng', 'O152A2K2');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('67295', 'SAKHLI0001', '7079895540473265', 'AkhigbeL@student.babcock.edu.ng', 'CAK2051b');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('67361', 'SFAJAB0002', '7079895540612821', 'FajobiA@student.babcock.edu.ng', 'B$C20BK$');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('65673', 'SENIVI0001', '7079895540571670', 'EniolaV@student.babcock.edu.ng', '0K0c1$1c');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('67271', 'SOMATI0001', '7079895540886078', 'OmajuwaT@student.babcock.edu.ng', '2$5ccC1O');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('67270', 'SBADES0001', '7079895540602368', 'EstherB@student.babcock.edu.ng', '50c1$KAC');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('67353', 'SMARPR0005', '7079895540691551', 'MartinsP@student.babcock.edu.ng', 'O2BBK1Cc');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('67357', 'STALTE0002', '7079895540972803', 'TalabiT@student.babcock.edu.ng', 'KA555b0c');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('67244', 'SABDTI0001', '7079895540422288', 'AbdulrasaqT@student.babcock.edu.ng', 'OBcB01$b');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('65641', 'SJAMFA0002', '7079895540682048', 'JamesF@student.babcock.edu.ng', '$A10$0Kc');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('67264', 'SSUNES0001', '7079895540969791', 'SundayE@student.babcock.edu.ng', '1O$$A$A0');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('66921', 'SADAOL0015', '7079895540431032', 'AdaramolaO@student.babcock.edu.ng', '2cOA1$05');
INSERT INTO adm_import1 (app_id, bussary_code, card_number, email_address, first_password) VALUES ('63457', 'SOSHOL0037', '7079895540876475', 'OluwatosinO@student.babcock.edu.ng', '1KcA2O05');



