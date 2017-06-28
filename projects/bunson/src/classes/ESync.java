import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.logging.Logger;
import java.util.Date;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;

import org.baraza.DB.BDB;
import org.baraza.DB.BQuery;

public class ESync{
    
    public static final String SUPPLIERS = "suppliers", CUSTOMER_CODES = "cust_codes", 
    CURRENCY = "currency", CAR_TYPES = "car_types",
    LOCATIONS = "locations";
    private static final String dbconfig = "java:/comp/env/jdbc/database";
    private static final String dbconfigOracle = "java:/comp/env/jdbc/databaseOracle";
    
    static boolean doLog = false;
    static boolean doSysOut = false;
	static Logger log = Logger.getLogger(ESync.class.getName());
    
    
    public ESync(){
        
    }
    
    public static String getExistSql(String type){
        String sql = "";
        
        if(type.equals(SUPPLIERS)){
            sql = "SELECT AIR_AGENT_CODE AS code FROM supplier_codes";
        }else if(type.equals(CUSTOMER_CODES)){
            sql = "SELECT customer_code AS code FROM customer_codes";
        }else if(type.equals(CURRENCY)){
            sql = "SELECT currency_symbol AS code FROM currency";
        }else if(type.equals(CAR_TYPES)){
            sql = "SELECT car_type_code AS code FROM car_types";
        }else if(type.equals(LOCATIONS)){
            sql = "SELECT location_code AS code FROM locations";
        }
        return sql;
    }
  
    public static String getEtravelCodesSql(String type, String excludes){
        String sql = "";
        
        if(type.equals(SUPPLIERS)){
            sql = "SELECT AIR_AGENT_CODE AS code, AIR_AGENT_NAME AS name FROM ID_AIRLINE_AGENT_MASTER";
            if(excludes.length() > 0) sql += " WHERE AIR_AGENT_AP_GROUP = 'CAR'  AND AIR_AGENT_CODE NOT IN(" + excludes + ")";
        }else if(type.equals(CUSTOMER_CODES)){
            sql = "SELECT ar_code AS code, ar_name AS name FROM id_ar_master";
            if(excludes.length() > 0) sql += " WHERE ar_code NOT IN(" + excludes + ")";
        }else if(type.equals(CURRENCY)){
            sql = "SELECT currency_code AS code, currency_name AS name FROM id_currency_master";
            if(excludes.length() > 0) sql += " WHERE currency_code NOT IN(" + excludes + ")";
        }else if(type.equals(CAR_TYPES)){
            sql = "SELECT car_type_code AS code, car_type_name AS name FROM id_car_type_master";
            if(excludes.length() > 0) sql += " WHERE car_type_code NOT IN(" + excludes + ")";
        }else if(type.equals(LOCATIONS)){
            sql = "SELECT location_code AS code, location_name AS name FROM id_location_master";
            if(excludes.length() > 0) sql += " WHERE location_code NOT IN(" + excludes + ")";
        } 
        if(doSysOut) System.out.print("\n" + type + " getEtravelCodesSql : " + sql);
        return sql;
    }
    
    public static String getInsertSql(String type, String values){
        String sql = "";
       
        if(type.equals(SUPPLIERS)){
            sql = "INSERT INTO supplier_codes(AIR_AGENT_CODE, AIR_AGENT_NAME) VALUES " + values;
        }else if(type.equals(CUSTOMER_CODES)){
            sql = "INSERT INTO customer_codes(customer_code, customer_name) VALUES "  + values;
        }else if(type.equals(CURRENCY)){
            sql = "INSERT INTO currency(currency_symbol,currency_name) VALUES "  + values;
        }else if(type.equals(CAR_TYPES)){
            sql = "INSERT INTO car_types(car_type_code, car_type_name)VALUES "  + values;
        }else if(type.equals(LOCATIONS)){
            sql = "INSERT INTO locations(location_code, location_name)VALUES "  + values;
        }
        if(doSysOut) System.out.print("\n" + type + " getInsertSql : " + sql);
        return sql.substring(0, sql.lastIndexOf(","));
    }
    
    public static void sync(String type){
        BDB db = new BDB(dbconfig);
        BDB dbOracle = new BDB(dbconfigOracle);
        
        ArrayList<String> codes = new ArrayList<String>();
        
        ResultSet rs = db.readQuery(getExistSql(type));
        try {
            while(rs.next()){
                codes.add(rs.getString("code"));
            }
            rs.close();
        }catch (SQLException e) {
            if(doSysOut) System.out.print("\nSQLException : " + e.toString());
        }catch (NullPointerException npe) {
            if(doSysOut) System.out.print("\nNullPointerException : " + npe.toString());
        }
        
        if(doSysOut) System.out.print("\n\nCodes : " + codes.size() + "\n" + codes.toString());

        String excludes = "";
        for(String s : codes){
            excludes += "'" + s + "',";
        }
        
        
        if(doSysOut) System.out.print("\n\n" + type + " > excludes: " + excludes  + "\n\n");
        if(excludes.length() > 0) excludes = excludes.substring(0, excludes.lastIndexOf(","));
        if(doSysOut) System.out.print("\n\n" + type + " > excludes: " + excludes  + "\n\n");
        
        ResultSet rsNew = dbOracle.readQuery(getEtravelCodesSql(type, excludes));
        String values = "";
        int newCodes = 0;
        try {
            while(rsNew.next()){
                newCodes++;
                values += "('" + rsNew.getString("code") + "','" + rsNew.getString("name").replaceAll("'", "''") + "'),";
            }
            rsNew.close();
        } catch (SQLException e) {
            if(doSysOut) System.out.print("\n" + type + " SQLException : " + e.toString());
        }catch (NullPointerException npe) {
            if(doSysOut) System.out.print("\n" + type + " NullPointerException : " + npe.toString());
        }
        
        
        if(newCodes > 0){
            System.out.print("\nThere Is new " + type + " Added");

            if(db.executeQuery(getInsertSql(type, values)) == null){
                System.out.print("\nPULLED " + type + " FROM ETRAVEL\n");

            }else{
                System.out.print("\n" + type + " FAILED TO PULL FROM ETRAVEL \n");
            }
        }else{
            System.out.print("\nNo New  " + type + " Added\n");
        }
        
        if(dbOracle != null){
            dbOracle.close();
            if(doSysOut) System.out.print("\n\n" + type + " Closing dbOracle Connection --------------");
        }
        
        if(db != null){
            db.close();
            if(doSysOut) System.out.print("\n\n" + type + " Closing db Connection --------------");
        } 
    }
    
    
    public static void syncBookings(){
        BDB db = new BDB(dbconfig);
        BDB dbOracle = new BDB(dbconfigOracle);
        
        String sql = "SELECT etravel_id, voucher_ref,entity_id,entity_name,user_name,driver_id,driver_name,is_backup::integer,air_agent_code,car_type_code,transfer_id,record_locator,customer_code,customer_name,currency_id, agreed_amount,booking_location,booking_date,payment_details,reference_data,pax_no,transfer_cancelled::integer,is_group::integer,create_source,group_contact::integer,group_member::integer,passanger_id,passanger_name,passanger_mobile,passanger_email,pickup_time,pickup,dropoff,other_preference, amount,processed::integer,pax_cancelled::integer,pickup_date,tab,transfer_assignment_id, car_id,confirmation_code,kms_out,kms_in,time_out,time_in,no_show::integer,no_show_reason,closed::integer,cancelled::integer,cancel_reason,transfer_flight_id,start_time,end_time,flight_date,start_airport,end_airport,airline,flight_num,create_key FROM etravel WHERE picked = false LIMIT 50;";
        
        String sqlEtravelPart1 = "INTO ID_CAR_BOOKINGS_BLOAT(car_booking_id, voucher_ref,entity_id,entity_name,user_name,driver_id,driver_name,is_backup,air_agent_code,car_type_code,transfer_id,record_locator,customer_code,customer_name,currency_id,agreed_amount,booking_location,booking_date,payment_details,reference_data,pax_no,transfer_cancelled,is_group,create_source,group_contact,group_member,passanger_id,passanger_name,passanger_mobile,passanger_email,pickup_time,pickup,dropoff,other_preference, amount,processed,pax_cancelled,pickup_date,tab,transfer_assignment_id,car_id,confirmation_code,kms_out,kms_in,time_out,time_in,no_show,no_show_reason,closed,cancelled,cancel_reason,transfer_flight_id,start_time,end_time,flight_date,start_airport,end_airport,airline,flight_num,create_key) VALUES ";
        /*GET ROWS NOT PICKED*/
        StringBuilder data_sb = new StringBuilder ();
        
        ArrayList<Integer> etravelIds = new ArrayList<Integer>();
        ResultSet rs = db.readQuery(sql);
        try {
            while(rs.next()){
                etravelIds.add(rs.getInt("etravel_id"));
                String row = "('" + rs.getInt("etravel_id") + "'," 
                 + "'" + rs.getString("voucher_ref") + "'," 
                 + "" + rs.getInt("entity_id") + "," 
                 + "'" + rs.getString("entity_name") + "'," 
                 + "'" + rs.getString("user_name") + "'," 
                 + "" + rs.getInt("driver_id") + "," 
                 + "'" + rs.getString("driver_name") + "'," 
                 + "'" + rs.getString("is_backup") + "'," 
                 + "'" + rs.getString("air_agent_code") + "'," 
                 + "'" + rs.getString("car_type_code") + "'," 
                 + "" + rs.getInt("transfer_id") + "," 
                 + "'" + rs.getString("record_locator") + "'," 
                 + "'" + rs.getString("customer_code") + "'," 
                 + "'" + rs.getString("customer_name") + "'," 
                 + "'" + rs.getString("currency_id") + "'," 
                 + "'" + rs.getString("agreed_amount") + "'," 
                 + "'" + rs.getString("booking_location") + "'," 
                 + " timestamp '" + rs.getString("booking_date") + "'," 
                 + "'" + rs.getString("payment_details") + "'," 
                 + "'" + rs.getString("reference_data") + "'," 
                 + "" + rs.getInt("pax_no") + "," 
                 + "" + rs.getInt("transfer_cancelled") + "," 
                 + "" + rs.getInt("is_group") + "," 
                 + "" + rs.getInt("create_source") + "," 
                 + "" + rs.getInt("group_contact") + "," 
                 + "" + rs.getInt("group_member") + "," 
                 + "" + rs.getInt("passanger_id") + "," 
                 + "'" + rs.getString("passanger_name") + "'," 
                 + "'" + rs.getString("passanger_mobile") + "'," 
                 + "'" + rs.getString("passanger_email") + "'," 
                 + "'" + rs.getString("pickup_time") + "'," 
                 + "'" + rs.getString("pickup") + "'," 
                 + "'" + rs.getString("dropoff") + "'," 
                 + "'" + rs.getString("other_preference") + "'," 
                 + "'" + rs.getString("amount") + "'," 
                 + "" + rs.getInt("processed") + "," 
                 + "" + rs.getInt("pax_cancelled") + "," 
                 + "'" + rs.getString("pickup_date") + "'," 
                 + "" + rs.getInt("tab") + "," 
                 + "" + rs.getInt("transfer_assignment_id") + "," 
                 + "" + rs.getInt("car_id") + "," 
                 + "'" + rs.getString("confirmation_code") + "'," 
                 + "'" + rs.getString("kms_out") + "'," 
                 + "'" + rs.getString("kms_in") + "'," 
                 + "'" + rs.getString("time_out") + "'," 
                 + "'" + rs.getString("time_in") + "'," 
                 + "" + rs.getInt("no_show") + "," 
                 + "'" + rs.getString("no_show_reason") + "'," 
                 + "" + rs.getInt("closed") + "," 
                 + "" + rs.getInt("cancelled") + "," 
                 + "'" + rs.getString("cancel_reason") + "'," 
                 + "" + rs.getInt("transfer_flight_id") + "," 
                 + "'" + rs.getString("start_time") + "'," 
                 + "'" + rs.getString("end_time") + "'," 
                 + "'" + rs.getString("flight_date") + "'," 
                 + "'" + rs.getString("start_airport") + "'," 
                 + "'" + rs.getString("end_airport") + "'," 
                 + "'" + rs.getString("airline") + "'," 
                 + "'" + rs.getString("flight_num") + "'," 
                 + "" + rs.getInt("create_key") + ") "; 
                //sqlEtravelInserts += (sqlEtravelPart1 + row);
                data_sb.append(sqlEtravelPart1 + row);
            }
            rs.close();
        }catch (SQLException e) {
            if(doSysOut) System.out.print("\nSQLException : " + e.toString());
        }catch (NullPointerException npe) {
            if(doSysOut) System.out.print("\nNullPointerException : " + npe.toString());
        }
        //IF NEW ROWS EXISTS
        System.out.print("\nNew Bookings Rows : " + etravelIds.size());
        String sqlEtravelInserts = "INSERT ALL " + data_sb.toString() + " SELECT * FROM dual";
        
        if(etravelIds.size() > 0){
            if(doSysOut) System.out.print("\n sqlEtravel : " + sqlEtravelInserts);
            
            if(dbOracle.executeQuery(sqlEtravelInserts) == null){
                System.out.print("PUSHED TO ETRAVEL ");

                String ids = etravelIds.toString();
                ids = ids.substring(1, ids.length()-1);

                String sqlUpdate = "UPDATE etravel SET picked =  true WHERE etravel_id IN (" + ids + ");";
                if(db.executeQuery(sqlUpdate) == null){
                    System.out.print("\n\n\nUPDATED : " + ids);
                }else{
                    System.out.print("\n\n\nFAILED TO UPDATE : " + ids);
                }
            }else{
                System.out.print("\n\n\nFAILED TO PUSH TO ETRAVEL ");
            }
            
            try {
                File file = new File("/opt/sync.sql");
                FileWriter fileWriter = new FileWriter(file);
                fileWriter.write(sqlEtravelInserts);
                fileWriter.flush();
                fileWriter.close();
            } catch (IOException e) {
                e.printStackTrace();
            }
            
            
        }
        
        if(dbOracle != null){
            dbOracle.close();
            if(doSysOut) System.out.print("\n\nBookings Closing dbOracle Connection --------------");
        }
        
        if(db != null){
            db.close();
            if(doSysOut) System.out.print("\n\n Bookings Closing db Connection --------------");
        }
    }
    
    
    
    
    
}