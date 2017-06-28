import java.io.IOException;
import java.io.PrintWriter;

import java.sql.ResultSet;
import java.sql.SQLException;

import javax.servlet.annotation.WebServlet;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;


import java.util.Map;
import java.util.HashMap;
import java.util.logging.Logger;
import java.util.Arrays;
import java.util.Calendar;
import java.util.Date;

import java.text.SimpleDateFormat;

import org.baraza.xml.BXML;
import org.baraza.xml.BElement;
import org.baraza.DB.BDB;
import org.baraza.DB.BQuery;

import org.json.simple.JSONArray;
import org.json.simple.JSONObject;
import org.json.simple.parser.JSONParser;
import org.json.simple.parser.ParseException;
//import org.json.simple.JSONException;

//@WebServlet("/pushtotransport")
public class PushToTransportServlet extends HttpServlet{
	static Logger log = Logger.getLogger(PushToTransportServlet.class.getName());
	@SuppressWarnings("unchecked")
	@Override
	public void doPost(HttpServletRequest req, HttpServletResponse rsp)	throws ServletException, IOException {
	   HttpSession session = req.getSession(false);
		log.info("Reached Push To Transport ");
		rsp.setContentType("application/json");
		PrintWriter out = rsp.getWriter();
		JSONObject jobj=new JSONObject();
		int success = 0; String message = "", agentivity = "";
		
		
		String jStringSegmentDep = req.getParameter("seg_data_dep");
        String jStringSegmentArr = req.getParameter("seg_data_arr");
        
		String jStringPax = req.getParameter("allpax");
		String jStringPaxArr = req.getParameter("allPaxArrival");
		
		/*String son = req.getParameter("son");
		String pcc = req.getParameter("pcc");*/
        
        String entity_id = session.getAttribute("entity_id").toString();
		String record_locator = req.getParameter("pnr_number");
		String customer_code = req.getParameter("customer_code");
        String customer_name = req.getParameter("customer_name");
		String payment_type = req.getParameter("payment_type");
		String currency = req.getParameter("currency");
		String booking_location = req.getParameter("booking_location");
		String agreed_amount = req.getParameter("agreed_amount");
        String pax_no = req.getParameter("pax_no");
        //String booking_date = req.getParameter("booking_date");
		String payment_details = req.getParameter("payment_details");
		String reference_data = req.getParameter("reference_data");
        String tc_email = req.getParameter("tc_email");
        
        String s_is_group = req.getParameter("is_group");
        boolean is_group = Boolean.parseBoolean(s_is_group);
        
        
        log.info(
            "entity_id : " + entity_id 
            + "\nrecord_locator : " + record_locator
            + "\ncustomer_code : " + customer_code
            + "\ncustomer_name : " + customer_name
            + "\npayment_type : " + payment_type
            + "\ncurrency : " + currency
            + "\nbooking_location : " + booking_location
            + "\nagreed_amount : " + agreed_amount
            + "\npax_no : " + pax_no
            //+ "\nbooking_date : " + booking_date
            + "\npayment_details : " + payment_details
            + "\nreference_data : " + reference_data
            +"\ntc_email : " + tc_email
            + "\nis_group : " + is_group
        );
        
        // get  segment details
		JSONParser jsonSegParser = new JSONParser();
		JSONObject jsonOSegmentsDep = null;
        JSONObject jsonOSegmentsArr = null;
		try {
			jsonOSegmentsDep = (JSONObject) jsonSegParser.parse(jStringSegmentDep);
            jsonOSegmentsArr = (JSONObject) jsonSegParser.parse(jStringSegmentArr);
			log.info("====\nJSON-SEGS DEP : " + jsonOSegmentsDep.toString());
            log.info("====\nJSON-SEGS ARR : " + jsonOSegmentsArr.toString());
		} catch (ParseException e) {
			log.severe("Error Parsing jStringSegment :  " + e.toString());
		}
        
        // depatures
		JSONParser jsonParser = new JSONParser();
		JSONArray jsonAPax = null;
		try {
			jsonAPax = (JSONArray) jsonParser.parse(jStringPax);
			log.info("====\nJSONARRAY-PAX (" + jsonAPax.size() + ") : " + jsonAPax.toString());
		} catch (ParseException e) {
			log.severe("Error Parsing jStringPax :  " + e.toString());
		}
        
        // arrivals
        JSONParser jsonParserArr = new JSONParser();
		JSONArray jsonAPaxArr = null;
		try {
			jsonAPaxArr = (JSONArray) jsonParserArr.parse(jStringPaxArr);
			log.info("====\nJSONARRAY-PAX ARR (" + jsonAPaxArr.size() + ") : " + jsonAPaxArr.toString());
		} catch (ParseException e) {
			log.severe("Error Parsing jStringPax :  " + e.toString());   
		}
        
        
        String sqlT = "INSERT INTO transfers(entity_id, record_locator, customer_code, customer_name, payment_type_id, currency_id, agreed_amount, "
            + " booking_location, booking_date, payment_details, reference_data, tc_email, pax_no, is_group, email_ready)"
            + " VALUES ( " + entity_id + ", '" + record_locator + "', '" + customer_code + "','" + customer_name + "'," + payment_type + ", '" + currency + "', '" + agreed_amount + "',"
            + " '" + booking_location + "', CURRENT_TIMESTAMP, '" + payment_details + "', '" + reference_data + "','" + tc_email + "', COALESCE('" + pax_no + "', 1) , " + is_group + ", true) RETURNING transfer_id";
        //pax_pickdate
        
        
        
        log.info("INSERT Transfer .................... SQl : \n" + sqlT );
        String dbconfig = "java:/comp/env/jdbc/database";
        BDB db = new BDB(dbconfig);
        
        
        ResultSet rs = db.readQuery(sqlT);
        int transfer_id = -1;
        try {
            while(rs.next()) {
                transfer_id = rs.getInt("transfer_id") ;
                //log.info("\n\n\ntransfer_id : " + rs.getInt("transfer_id") + "\n\n\n :   > " + transfer_id + "\n\n\n");
            }
            
            log.info("\n\n\ntransfer_id :  > " + transfer_id + "\n\n\n");
            
            if(jsonOSegmentsDep.size() > 0){
                String sqlFlightDep = "INSERT INTO transfer_flights(transfer_id, start_time, end_time, flight_date, start_airport, end_airport, airline, flight_num, tab)"
                        + " VALUES (" + transfer_id + ", '" + jsonOSegmentsDep.get("StartTm") + "'::time, '" + jsonOSegmentsDep.get("EndTm") + "'::time, to_date('" + jsonOSegmentsDep.get("Dt") + "', 'DD/MM/YYYY'), '" + jsonOSegmentsDep.get("StartAirp") + "', '" + jsonOSegmentsDep.get("EndAirp") + "', '" + jsonOSegmentsDep.get("AirV") + "', '" + jsonOSegmentsDep.get("FltNum") + "', 1);";
                log.info("\n\n\nsqlFlightDep : " + sqlFlightDep + "\n\n\n");
                if(db.executeQuery(sqlFlightDep) == null){
                    log.info("Depature Flight Added");
                }else{
                    log.severe("Adding Depature Flight Failed");
                }
            }
            
            if(jsonOSegmentsArr.size() > 0){
                String sqlFlightArr = "INSERT INTO transfer_flights(transfer_id, start_time, end_time, flight_date, start_airport, end_airport, airline, flight_num, tab)"
                        + " VALUES (" + transfer_id + ", '" + jsonOSegmentsArr.get("StartTm") + "'::time, '" + jsonOSegmentsArr.get("EndTm") + "'::time, to_date('" + jsonOSegmentsArr.get("Dt") + "', 'DD/MM/YYYY'), '" + jsonOSegmentsArr.get("StartAirp") + "', '" + jsonOSegmentsArr.get("EndAirp") + "', '" + jsonOSegmentsArr.get("AirV") + "', '" + jsonOSegmentsArr.get("FltNum") + "', 2);";
                log.info("\n\n\nsqlFlightArr : " + sqlFlightArr + "\n\n\n");
                if(db.executeQuery(sqlFlightArr) == null){
                    log.info("Arrival Flight Added");
                }else{
                    log.severe("Adding Arrival Flight Failed");
                }
            }
            
            if(transfer_id != -1){
                String sqlPax = "INSERT INTO passangers( transfer_id, passanger_name, passanger_mobile, passanger_email, car_type_code, pickup_date, pickup_time, pickup, dropoff, other_preference, amount, tab, group_contact, group_member) VALUES ";
                for(int i = 0; i < jsonAPax.size(); i++){
                    JSONObject jsonOPax = (JSONObject) jsonAPax.get(i);
                    int tab = 1;
                    String amt = jsonOPax.get("pax_amount").toString().trim();
                    if(amt.equals("")) amt = "0";
                    
                    
                    sqlPax += "( " + transfer_id        + ", '" 
                        + jsonOPax.get("pax_name")      + "', '" 
                        + jsonOPax.get("pax_mobile")    + "', '" 
                        + jsonOPax.get("pax_email")     + "', '" 
                        + jsonOPax.get("pax_car_type")  + "', " 
                        + " to_date('" + jsonOPax.get("pax_pickdate") + "', 'dd-MM-yyyy') " + ", '"
                        + jsonOPax.get("pax_time")      + "', '" 
                        + jsonOPax.get("pax_pickup")    + "', '" 
                        + jsonOPax.get("pax_dropoff")   + "', '" 
                        + jsonOPax.get("pax_other_pref")+ "', '" 
                        + amt                        + "', " 
                        + tab+ " , " + jsonOPax.get("group_contact") + ", " + is_group + "), ";
                }
                
                
                
                
                for(int i = 0; i < jsonAPaxArr.size(); i++){
                    JSONObject jsonOPax = (JSONObject) jsonAPaxArr.get(i);
                    int tab = 2;
                    
                    String amtArr = jsonOPax.get("pax_amount").toString().trim();
                    if(amtArr.equals("")) amtArr = "0";
                    
                    
                    sqlPax += "( " + transfer_id        + ", '" 
                        + jsonOPax.get("pax_name")      + "', '" 
                        + jsonOPax.get("pax_mobile")    + "', '" 
                        + jsonOPax.get("pax_email")     + "', '" 
                        + jsonOPax.get("pax_car_type")  + "', "
                        + " to_date('" + jsonOPax.get("pax_pickdate") + "', 'dd-MM-yyyy') " + ", '"
                        + jsonOPax.get("pax_time")      + "', '" 
                        + jsonOPax.get("pax_pickup")    + "', '" 
                        + jsonOPax.get("pax_dropoff")   + "', '" 
                        + jsonOPax.get("pax_other_pref")+ "', '"
                        + amtArr                        + "', " 
                        + tab+ " , " + jsonOPax.get("group_contact") + ", " + is_group + "), ";
                }
                
                log.info("\n\n\nsqlPax : " + sqlPax + "\n\n\n");
                log.info("\n\n\nsqlPax SUB : " + sqlPax.substring(0, sqlPax.lastIndexOf(",")) + "\n\n\n");
                
                sqlPax = sqlPax.substring(0, sqlPax.lastIndexOf(","));
                
                if(db.executeQuery(sqlPax) == null){
                    success = 1; 
                    message = "Push Successful";
                    SimpleDateFormat sdf = new SimpleDateFormat("ddMMM/hhmm/");
                    agentivity = "NP.GS*TRANSFER/BUNSON/NBO Centre/NBO/" + sdf.format(Calendar.getInstance().getTime()) + transfer_id;
                }else{
                    success = 0; 
                    message = "Push Failed. Please Try Again";
                }
                
            }
            
            rs.close();
        } catch (SQLException e) {
            log.info("SQLException : " + e.toString());
        }
        db.close();
        
        
        if(db != null){
            db.close();
            log.info("Closing Connection --------------");
        }
        
        
		//success = 1; 
		//message = "Push Successful";
		
		jobj.put("success", success);
		jobj.put("message", message);
        jobj.put("agentivity", agentivity);
        
        
        log.info("Response : " + jobj.toString());
		out.print(jobj);
	}
}

