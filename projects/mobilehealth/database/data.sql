-- mother information
INSERT INTO mother_info_defs( mother_info_def_id,question, details ) VALUES
(1, 'Pregnant','Record  by  Indicating  with a tick (✔) whether a household female member is  pregnant or (X) if the household female member is  not pregnant. The CHV should observe or ask the woman in the household. Record N/A if the member is not a woman of reproductive age (15-49 years)'),
(2, 'Pregnant woman counselled on Individual Birth Plan (IBP)','Record  by  Indicating  with a tick (✔) whether the pregnant woman is counselled on Individual Birth Plan (IBP) or (X) if not. Record N/A if the member is not a pregnant woman'),
(3, 'Woman delivered by unskilled attendant','Record   by marking with a tick (✔ )  if delivery since the last visit was by unskilled attendant.Note – traditional birth attendants (TBA)  are considered unskilled. Record N/A if the member is not a woman who delivered since last visit'),
(4, 'Woman  delivered by skilled attendant','Record   by marking with a tick (✔ )  if delivery since the last visit was by skilled attendant.Note – traditional birth attendants (TBA) are considered not skilled attendants. Record N/A if the member is not a woman who delivered since last visit'),
(5, 'New-born visited at home within 48 hours of delivery','Record  by  Indicating  with a tick (✔) if New-born was visited at home within 48 hours of delivery or (X) if not. Record N/A if the member is not a new-born'),
(6, 'Mother with new-born counselled on Exclusive Breast Feeding (EBF)','Record  by  Indicating  with a tick (✔) if Mother with new-born (0-28 days) is counselled on Exclusive Breast Feeding (EBF) or (X) if not. Record N/A if the household member is not a mother of a new-born'),
(7, 'Woman 15-49yrs provided with Family Planning commodities by CHVs','Record  by  Indicating  with a tick (✔) if a Woman 15-49 years is provided with Family Planning commodities by CHVs or (X) if a woman of 15-49 years was not provided. Record N/A if the member is not a woman of reproductive age (15-49 years)')


-- child information
INSERT INTO child_info_defs( child_info_def_id, question, details ) VALUES
(1, 'Gender', '1 male, 2 femail'),
(2, 'Child 0-59 months participating in growth monitoring','Record  by  Indicating  with a tick (✔) if a Child 0-59 months participating in growth monitoring or (X) if not. Record N/A if the household member is not a child of 0-59 months'),
(3, 'Child 6-59 months with MUAC (Red) indicating severe malnutrition','Record  by  Indicating  with a tick (✔) if a Child 6-59 months has MUAC (Red) indicating severe malnutrition or (X) if not. Record N/A if the household member is not a child of 6-59 months'),
(4, 'Child 6-59 months with MUAC (Yellow) indicating  moderate malnutrition','Record  by  Indicating  with a tick (✔) if a Child 6-59 months has MUAC (Yellow) indicating moderate malnutrition or (X) if not. Record N/A if the household member is not a child of 6-59 months'),
(5, 'Child  12-59 months dewormed','Record by marking a tick (✔ )  when the child 12-59 months  in the household was dewormed in the last 6 months or (X) if the child was not . Record N/A if the household member is not a child of 12-59 months')

INSERT INTO referral_info_defs( referral_info_def_id, question, details) VALUES
(1, 'Pregnant woman referred for ANC', 'Record by marking a tick (✔ )  when the Pregnant woman is referred for ANC or (X) if not. Record N/A if the household member is not a pregnant woman'),
(2, 'Pregnant women referred for skilled delivery','Record by marking a tick (✔ )  when the Pregnant woman is referred for skilled delivery or (X) if not. Record N/A if the household member is not a pregnant woman'),
(3, 'Woman referred for family planning services','Record by marking a tick (✔ )  when the woman of 15-49 years is referred for family planning services or (X) if not. Record N/A if the household member is not a woman of 15-49 years'),
(4, 'Home delivery referred for Post Natal Care (PNC) Services','Record by marking a tick (✔ ) if a home delivery is referred for Post Natal Care (PNC) Services or (X) if not. Record N/A if the household member is not a mother who delivered at home'),
(5, 'Child 0-11 months referred for immunization','Record by marking a tick (✔ ) if a child 0-11 months is referred for immunization services or (X) if not. Record N/A if the household member is not a child of 0-11 months'),
(6, 'Child 6-59 months referred for Vitamin A supplementation','Record by marking a tick (✔ ) if a child between 6 months of age to 59 Months is referred for Vitamin A supplementation  or (X) if not. Record N/A if the household member is not a child of 6-59 months'),
(7, 'Cough more than 2 weeks referred','Record by marking a tick (✔ ) if a chronic cough for two or more weeks is referred to a  health facility  or (X) if not. Record N/A when the household member has  not had chronic cough or had had it for less than 2 weeks'),
(8, 'Referred for HIV Counselling and Testing (HCT)','Record by marking a tick (✔ ) if  referred for HIV Counselling and Testing (HCT) or (X) if not. Record N/A for a small child'),
(9, 'Elderly (60 +) referred for routine health check-ups','Record by marking a tick (✔ ) if elderly  (60 years and above) is referred to a health facility for routine check-ups or (X) if not. Record N/A if the member is not eldery with 60 or more years'),
(10, 'A: Diabetes','Known cases of chronic illness  referred'),
(11, 'B: Cancer','Known cases of chronic illness  referred'),
(12, 'C: Mental Illness','Known cases of chronic illness  referred'),
(13, 'D: Hypertension','Known cases of chronic illness  referred'),
(14, 'E: Others (specify in remarks)','Known cases of chronic illness  referred');


-- defaulters info
INSERT INTO defaulters_info_defs( defaulters_info_def_id, question, details ) VALUES
(1, 'ANC defaulter referred', 'Record by marking a tick (✔ ) if  ANC defaulter is referred to a health facility or (X) if not. Record N/A if the member is not an ANC defaulter'),
(2, 'Immunization defaulter referred', 'Record by marking a tick (✔ ) if Child 0-59 months of age who defaulted on immunization has been referred for immunization or (X) if not. Record N/A if the member is not a child of 0-59 months or is a child of 0-59 months but did not default on immunization'),
(3, 'TB treatment defaulter traced and referred', 'Record by marking a tick (✔ ) if a Tuberculosis (TB) defaulter is referred to a health facility or (X) if not. Record N/A if the member has not had TB or has had TB but did not default'),
(4, 'ART defaulter referred', 'Record by marking a tick (✔ ) if an ART defaulter is referred to a health facility or (X) if not. Record N/A if the member has not been on ART or has been on ART but has not defaulted'),
(5, 'HIV exposed infant (HEI) defaulters traced and referred','Record by marking a tick (✔ ) if an HIV exposed infant (HEI) defaulter is traced and referred to a health facility or (X) if not. Record N/A if the member is not an HIV exposed infant (HEI) defaulter');



INSERT INTO death_info_defs(death_info_def_id, question, details)VALUES
(1, 'A: 0-28 days', '(Record all deaths between zero to 28 days of age) which occurred in the month'),
(2, 'b: 29 days-11 months', '(Record all deaths between 29 days to 11 months of age) which occurred in the month'),
(3, 'c: 12-59 months', '(Record all deaths between 12-59 months of age) which occurred in the month'),
(4, 'd: Maternal', '(Record all deaths of women during pregnancy or child birth or within 42 days after delivery) which occurred in the month'),
(5, 'e: Other deaths', '(Record all deaths in the household and not counted above) which occurred in the month');

-- household info
INSERT INTO household_info_defs( household_info_def_id, question, details ) VALUES
(1, 'Household  has a  functional latrine in use','Observe and record with a tick (✔)  if the household  has a functional latrine in use or (X) if the household does not have a functional  latrine in use. This also includes all types of toilets and whether they are functional or not'),
(2, 'Household with hand washing facilities','Observe and record with a tick (✔)  if the  household has hand  washing  facilities (e.g.  hand wash basin, tippy tap, leaky  tin) or (X) if the  household does not have hand  washing  facilities'),
(3, 'Household  using treated water', 'Ask and record with a tick (✔) if the household is always using treated　water　for　drinking  or (X) if the household is not always using treated   water for drinking')


-- MOH 515 DATA



INSERT INTO demograpics_515_defs(demograpics_515_def_id, demograpics_question, demograpics_details) VALUES
(1, 'Total households','Total number of households in the Community Health Unit'),
(2, 'Total number of households visited','Total number of households visited in the month'),
(3, 'Total population','Total number of people in the Community Health Unit'),
(4, 'Total women 15-49 years','Total number of women aged 15 - 49 years in the CHU'),
(5,' Total pregnant women','Total number of pregnant women in the CHU'),
(6, 'Total children 0-28 days','Total number of children 0-28 days in the CHU'),
(7, 'Total children 29 days -11 months','The number of children of  29 days -11 months in the CHU'),
(8, 'Total children 12-59 months','The number of children of 12-59 months in the CHU'),
(9, 'Total Children 5-12 years','The number of children of 5-12 years in the CHU'),
(10, 'Total adolescent and youth - Girls (13 - 24 years)','The number of adolescents and youths that are girls between the age of 13 - 24 years in the CHU'),
(11, 'Total adolescent and youth - Boys (13 - 24 years)','The number of adolescents and youths that are boys between the age of 13 - 24 years in the CHU'),
(12, 'Total Population 25-59 years','The number of people who are 25-59 years old in the CHU'),
(13, 'Total population of the elderly (60+ years)','The number of people who are 60 and above in the CHU');


INSERT INTO household_515_defs(household_515_def_id,household_question,household_details ) VALUES
(1, 'Number of households using treated water','Total number of Households using treated water in the CHU '),
(2, 'Number of households with hand washing facilities e.g. leaky tins in use','Total number of Households in the CHU having hand washing facilities'),
(3,	'Number of households with functional latrines','Total number of Households in the CHU that are having a functional latrine in use');


INSERT INTO motherchild_515_defs( motherchild_515_def_id ,motherchild_question,motherchild_details ) VALUES
(1, 'Number of new-borns 0-28 days visited at home within 48 hours of delivery','Total number of new-borns 0-28 days visited at home within 48 hours of birth'),
(2, 'Number of Mothers with new-borns counselled on Exclusive Breastfeeding','Number of mothers with new born babies counselled on exclusive breastfeeding'),
(3, 'Number of children 0-59 months  participating in  growth monitoring','The number of children 0-59 months using growth monitoring  services'),
(4, 'Total Deliveries','Record the total number of deliveries both attended to or not attended to by trained birth attendants'),
(5, 'Number of deliveries by Skilled Birth Attendants','Record the total number of deliveries attended to by skilled birth attendants'),
(6, 'Number of under-age pregnancies (under 18 years)','Record the total number of pregnancies for mothers under 18 year age'),
(7, 'Number of women(15-49yrs) provided with FP commodities','The total number of women between 15 - 49 years provided with family planning commodities by CHVs'),
(8, 'Number of children 12-59 months dewormed','The total number of children of 12-59 months de-wormed');

INSERT INTO treatment_515_defs(treatment_515_def_id, treatment_question, treatment_details  ) VALUES
(1, 'Number of fever cases managed','The total number of fever cases managed '),
(2, 'Number of Fever cases less than 7 days RDT done','Total number of fever cases of less than 7 days for which Rapid Diagnostic Test has been done '),
(3, 'Number of Fever cases less than 7 days RDT +ve','Total number of fever cases of less than 7 days for which Rapid Diagnostic Test has been done  and the result is positive'),
(4, 'Number of 0-59 months Malaria Cases (RDT +ve) treated with ACT','Total number under 5 years malaria cases treated with ACT'),
(5, 'Number of over 5 year old Malaria Cases (RDT +ve) treated with ACT','Total number of over 5 year old malaria cases treated with ACT'),
(6, 'Number of diarrhoea cases identified in children of 0-59 months','The total number of diarrhoea cases identified in children of 0-59 months'),
(7, 'Number of children of 12-59 months with diarrhoea treated with ORS and Zinc','The total number of diarrhoea cases in children of 12-59 months managed by the CHV, by giving ORS  and Zinc'),
(8, 'Number of children of 0-59 months presenting with fast breathing','Total number of children of 0-59 months presenting with fast breathing'),
(9, 'Number of children of 0-59 months presenting with fast breathing treated with Amoxycillin','Total number of children of 0-59 months presenting with fast breathing treated with Amoxycillin by the CHVs'),
(10, 'Number of injuries and wounds managed','Total number of injuries and wounds cases managed  by the CHVs');



INSERT INTO referrals_515_defs(referrals_515_defs_id ,referrals_question , referrals_details ) VALUES
(1, 'Number of referrals for ANC','Total number of pregnant women in the CHU referred for ANC '),
(2, 'Number of referrals for skilled delivery','Total number of pregnant women referred for skilled delivery '),
(3, 'Number of new-borns with danger signs referred','Total number of new-borns with danger signs referred '),
(4, 'Number of children of 0-11 months age  referred for immunization','The number of children of 0-11 months age referred for immunization  '),
(5, 'Number of children 6 - 59 Months referred for Vitamin A supplementation','The total number of children between the ages 6 months and 59 months referred for Vitamin A supplementation '),
(6, 'Number of referrals for severe malnutrition','Total number of referrals for severe malnutrition (red on MUAC) '),
(7, 'Number of referrals for moderate malnutrition','Total number of referrals for moderate malnutrition yellow on MUAC) '),
(8, 'Number of referrals for cases with cough for 2 or more weeks','Total number of referrals for cases with cough for 2 or more weeks '),
(9, 'Number of referrals for HIV Counselling and Testing (HCT)','Total number of referrals for HIV Counselling and Testing (HCT) '),
(10,'Number of referrals for routine health check-ups for the elderly (60+ years)','Total number of referrals for routine health check-ups for the elderly (60+ years) '),
(11,'Cases of known chronic illness referred - Diabetes', 'Total number of known cases with  a particular chronic illnesses referred. It should be recorded per illness i.e. Number of  Diabetes, cancer, mental illness, hypertension, chronic respiratory diseases referred. It is a chronic illness if someone has been unwell for 1 year or more without healing'),
(12,'Cases of known chronic illness referred - Cancer', 'Total number of known cases with  a particular chronic illnesses referred. It should be recorded per illness i.e. Number of  Diabetes, cancer, mental illness, hypertension, chronic respiratory diseases referred. It is a chronic illness if someone has been unwell for 1 year or more without healing'),
(13,'Cases of known chronic illness referred - Mental Illness', 'Total number of known cases with  a particular chronic illnesses referred. It should be recorded per illness i.e. Number of  Diabetes, cancer, mental illness, hypertension, chronic respiratory diseases referred. It is a chronic illness if someone has been unwell for 1 year or more without healing'),
(14,'Cases of known chronic illness referred - Hypertension', 'Total number of known cases with  a particular chronic illnesses referred. It should be recorded per illness i.e. Number of  Diabetes, cancer, mental illness, hypertension, chronic respiratory diseases referred. It is a chronic illness if someone has been unwell for 1 year or more without healing'),
(15,'Cases of known chronic illness referred - Chronic Respiratory Diseases ', 'Total number of known cases with  a particular chronic illnesses referred. It should be recorded per illness i.e. Number of  Diabetes, cancer, mental illness, hypertension, chronic respiratory diseases referred. It is a chronic illness if someone has been unwell for 1 year or more without healing');


INSERT INTO defaulters_515_defs(defaulters_515_def_id ,defaulters_question, defaulters_details ) VALUES
(1 , 'Number of defaulters traced and referred for: - ANC', 'Total number of defaulters for the various health services traced and referred. The data should be recorded per service i.e. Tuberculosis treatment, ANC, ART and Immunization '),
(2 , 'Number of defaulters traced and referred for: - Immunization', 'Total number of defaulters for the various health services traced and referred. The data should be recorded per service i.e. Tuberculosis treatment, ANC, ART and Immunization '),
(3 , 'Number of defaulters traced and referred for: - Tuberculosis treatment', 'Total number of defaulters for the various health services traced and referred. The data should be recorded per service i.e. Tuberculosis treatment, ANC, ART and Immunization '),
(4 , 'Number of defaulters traced and referred for: - ART', 'Total number of defaulters for the various health services traced and referred. The data should be recorded per service i.e. Tuberculosis treatment, ANC, ART and Immunization ');



INSERT INTO death_515_defs(death_515_def_id, death_question, death_details ) VALUES

(1, 'Number of deaths in the month	0-28 days', 'record all deaths between zero to 28 days of age'),
(2, 'Number of deaths in the month	29 days -11 months', 'record all deaths between zero to 11 months of age'),
(3, 'Number of deaths in the month	12-59 months', 'Record all deaths between 12 - 59 months of age'),
(4, 'Number of deaths in the month	Maternal', 'Record all deaths of women during pregnancy or child birth or within 42 days after delivery'),
(5, 'Number of deaths in the month	Other deaths', 'record all deaths in the household and not counted above'),
(6, 'Number of deaths in the month	Total deaths', 'add or sum up all the deaths'),
(7, 'Total number of community dialogue days held', 'The number of community dialogue days held in the previous month These days are held once per quarter. Therefore, in a year, there should be 4 community dialogue days'),
(8, 'Total number of community action days held', 'The number of action days held in the previous month. There should be held once a month, so a total of 12 such days per year'),
(9, 'Total number of community monthly meetings held', 'The number of monthly meetings between the CHEW and the CHV');




INSERT INTO commodities_515_defs(commodity_515_def_id, commodity_question,commodity_details ) VALUES
(1, 'CHU issued with any commodities?','Record Yes or No to indicate whether or not the CHU was issued with any commodities'),
(2, 'Antimalarial (ACTs 6s and 12s)','Did the community health unit experience stock-outs of more than 7 days'),
(3, 'Oral Rehydration Salt','Did the community health unit experience stock-outs of more than 7 days'),
(4, 'Zinc','Did the community health unit experience stock-outs of more than 7 days'),
(5, 'Rapid Diagnostic Test Kit','Did the community health unit experience stock-outs of more than 7 days'),
(6, 'Condoms','Did the community health unit experience stock-outs of more than 7 days'),
(7, 'Oral Contraceptives ','Did the community health unit experience stock-outs of more than 7 days'),
(8, 'Iodine Solution','Did the community health unit experience stock-outs of more than 7 days'),
(9, 'Chlorine Tablets','Did the community health unit experience stock-outs of more than 7 days'),
(10, 'Albedazole Tablets','Did the community health unit experience stock-outs of more than 7 days'),
(11, 'Tetracycline Eye Ointment','Did the community health unit experience stock-outs of more than 7 days'),
(12, 'Paracetamol','Did the community health unit experience stock-outs of more than 7 days');


INSERT INTO others_515_defs(others_515_def_id,  others_question, others_details ) VALUES
(1, 'Remarks/Others', 'Enter any general or specific remarks about the summary of indicators or any other services rendered and not summarized in the indicators above e.g. FP referrals, IPT (Intermittent Presumptive Treatment for pregnant women)');
