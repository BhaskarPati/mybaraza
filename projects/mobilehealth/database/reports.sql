
SELECT org_id, org_name, county_id, county_name, sub_county_id, sub_county_name,
      SUM(no_of_chvs) AS no_of_chvs, SUM(total_chws_reported) AS total_chws_reported,
SUM(indicator_1) AS indicator_1 ,SUM(indicator_2) AS indicator_2 ,SUM(indicator_3) AS indicator_3 ,
SUM(indicator_4) AS indicator_4 ,SUM(indicator_5) AS indicator_5 ,SUM(indicator_6) AS indicator_6 ,SUM(indicator_7) AS indicator_7 ,
SUM(indicator_8) AS indicator_8 ,SUM(indicator_9) AS indicator_9 ,SUM(indicator_10) AS indicator_10 ,SUM(indicator_11) AS indicator_11 ,
SUM(indicator_12) AS indicator_12 ,SUM(indicator_13) AS indicator_13 ,SUM(indicator_14) AS indicator_14 ,SUM(indicator_15) AS indicator_15 ,
SUM(indicator_16) AS indicator_16 ,SUM(indicator_17) AS indicator_17 ,SUM(indicator_18) AS indicator_18 ,SUM(indicator_19) AS indicator_19 ,
SUM(indicator_20) AS indicator_20 ,SUM(indicator_21) AS indicator_21 ,SUM(indicator_22) AS indicator_22 ,SUM(indicator_23) AS indicator_23 ,
SUM(indicator_24) AS indicator_24 ,SUM(indicator_25) AS indicator_25 ,SUM(indicator_26) AS indicator_26 ,SUM(indicator_27) AS indicator_27 ,
SUM(indicator_28) AS indicator_28 ,SUM(indicator_29) AS indicator_29 ,SUM(indicator_30) AS indicator_30 ,SUM(indicator_31) AS indicator_31 ,
SUM(indicator_32) AS indicator_32 ,SUM(indicator_33) AS indicator_33 ,SUM(indicator_34) AS indicator_34 ,SUM(indicator_35) AS indicator_35 ,
SUM(indicator_36) AS indicator_36 ,SUM(indicator_37) AS indicator_37 ,SUM(indicator_38) AS indicator_38 ,SUM(indicator_39) AS indicator_39 ,
SUM(indicator_40) AS indicator_40 ,SUM(indicator_41) AS indicator_41 ,SUM(indicator_42) AS indicator_42 ,SUM(indicator_43) AS indicator_43 ,
SUM(indicator_44) AS indicator_44 ,SUM(indicator_45) AS indicator_45 ,SUM(indicator_46) AS indicator_46 ,SUM(indicator_47) AS indicator_47 ,
SUM(indicator_48) AS indicator_48 ,SUM(indicator_49) AS indicator_49 ,SUM(indicator_50) AS indicator_50 ,SUM(indicator_51) AS indicator_51 ,
SUM(indicator_52) AS indicator_52 ,SUM(indicator_53) AS indicator_53 ,SUM(indicator_54) AS indicator_54 ,SUM(indicator_55) AS indicator_55 ,
SUM(indicator_56) AS indicator_56 ,SUM(indicator_57) AS indicator_57 ,SUM(indicator_58) AS indicator_58 ,SUM(indicator_59) AS indicator_59 ,
SUM(indicator_60) AS indicator_60 ,SUM(indicator_61) AS indicator_61 ,SUM(indicator_62) AS indicator_62 ,SUM(indicator_63) AS indicator_63 ,
SUM(indicator_64) AS indicator_64 ,SUM(indicator_65) AS indicator_65
  FROM vw_surveys_515_details WHERE
sub_county_id = 1

--AND start_date >= '2015-01-01'::date
--AND start_date <= '2015-01-01'::date
--AND end_date >= '2015-08-31'::date
--AND end_date <= '2015-08-31'::date

 GROUP BY org_id, org_name, county_id, county_name, sub_county_id, sub_county_name
