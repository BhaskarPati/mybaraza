import java.io.IOException;
import java.io.PrintWriter;

import java.sql.ResultSet;
import java.sql.SQLException;

import javax.servlet.annotation.WebServlet;
import javax.servlet.RequestDispatcher;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import java.util.Map;
import java.util.HashMap;
import java.util.logging.Logger;

import org.baraza.xml.BXML;
import org.baraza.xml.BElement;
import org.baraza.DB.BDB;
import org.baraza.DB.BQuery;

import org.json.simple.JSONArray;
import org.json.simple.JSONObject;


@WebServlet("/driverrequest")
public class DriverRequest extends HttpServlet{
	static Logger log = Logger.getLogger(DriverRequest.class.getName());
	RequestDispatcher dispatcher;
	static final boolean doLog = true;
	@SuppressWarnings("unchecked")
	@Override
	public void doPost(HttpServletRequest req, HttpServletResponse resp)	throws ServletException, IOException {
		HttpSession session = req.getSession(false);
        
        
		String tag = req.getParameter("tag");
		if(tag.equals("") || tag == null){
			dispatcher = req.getRequestDispatcher("bunson");
			dispatcher.forward(req, resp);
		}
		
		
		else if(tag.equals("searchAssignment")){
            /*if(session.getAttribute("driver_id") == null || session.getAttribute("driver_name") == null){
                dispatcher = req.getRequestDispatcher("bunson");
                dispatcher.forward(req, resp);
            }
            */
            
            
			if(doLog) log.info("Loading assignments " + tag + "....................");
			JSONObject jobj = new JSONObject();

			String dbconfig = "java:/comp/env/jdbc/database";
			BDB db = new BDB(dbconfig);
            
            String reference = req.getParameter("reference");
			
            /*String sql = "SELECT transfer_assignment_id, registration_number, passanger_name,passanger_mobile, passanger_email, pickup_time, pickup, dropoff, other_preference, kms_out, kms_in, time_out,time_in, closed, "
                    + " no_show, no_show_reason , cancelled, cancel_reason, sys_file_id , sys_file_id::text || 'ob' || substr(file_name, strpos(file_name, '.'), 4) AS file_name"
                 + " FROM vw_transfer_assignments INNER JOIN sys_files ON  sys_files.table_id= vw_transfer_assignments.transfer_assignment_id "
                 + " WHERE  sys_files.table_name = 'transfer_assignments' AND transfer_assignment_id = " + reference + " AND  driver_id = " + session.getAttribute("driver_id");
            
            */
            
            String sql = "SELECT a.*, COALESCE(b.file_name , 'none'::text) AS file_name FROM "
                        + " (SELECT transfer_assignment_id, registration_number, passanger_name,passanger_mobile, passanger_email, pickup_time, pickup, dropoff, "
                        + "     other_preference, kms_out, kms_in, time_out,time_in, closed,  no_show, no_show_reason , cancelled, cancel_reason "
                        + "     FROM vw_transfer_assignments_create WHERE transfer_assignment_id = " + reference + " AND  driver_id = " + session.getAttribute("driver_id") + ") AS a "
                        + " FULL OUTER JOIN " 
                        + " (SELECT table_id, sys_file_id::text || 'ob' || substr(file_name, strpos(file_name, '.'), 4) AS file_name FROM sys_files "
                        + "     WHERE  table_name = 'transfer_assignments' AND table_id = " + reference + ") AS b"
                        + " ON a.transfer_assignment_id = b.table_id  LIMIT 1";
            
            
            
            
            if(doLog) log.info("SQL : " + sql);
			ResultSet rs = db.readQuery(sql);
			int success = 0; 
			String message = "No Options Available";
			try {
				while(rs.next()) {
					success = 1; message = "Options Available";
					jobj.put("reference", rs.getString("transfer_assignment_id"));
					jobj.put("paxName", rs.getString("passanger_name"));
                    jobj.put("paxMobile", rs.getString("passanger_mobile"));
                    jobj.put("paxTime", rs.getString("pickup_time"));
                    jobj.put("paxPickUp", rs.getString("pickup"));
                    jobj.put("paxDropoff", rs.getString("dropoff"));
                    jobj.put("paxPref", rs.getString("other_preference"));
                    jobj.put("carRegNo", rs.getString("registration_number"));
                    
                    jobj.put("kmsout", rs.getString("kms_out"));
                    jobj.put("kmsin", rs.getString("kms_in"));
                    jobj.put("timeout", rs.getString("time_out"));
                    jobj.put("timein", rs.getString("time_in"));
                    jobj.put("closed", rs.getString("closed"));
                    jobj.put("isNoShow", rs.getString("no_show"));
                    jobj.put("reason", rs.getString("no_show_reason"));
                    jobj.put("file_name", rs.getString("file_name"));
                    
                    jobj.put("isCancelled", rs.getString("cancelled"));
                    jobj.put("cancelReason", rs.getString("cancel_reason"));
				}
				rs.close();				
			} catch (SQLException e) {
				log.info("SQLException : " + e.toString());
			}
			if(db != null){
				db.close();
				if(doLog) log.info("Closing Connection --------------");
			}
			
			//log.info("\n Message : " + tag + " - " + message);
            if(doLog) log.info("JSON ASSIGNEMNT : " + jobj.toString());
			jobj.put("success", success);			
	        jobj.put("message", message);
			resp.setContentType("application/json");
			PrintWriter out = resp.getWriter();
	        out.print(jobj);
			
		}//dropdown
        
        //save', kmsout:kmsout,  kmsin:kmsin
        else if(tag.equals("save")){
            String dbconfig = "java:/comp/env/jdbc/database";
			BDB db = new BDB(dbconfig);log.info("Connection Opened--------------");
			int success = 0; String message = "Invalid Credentials";
			String kmsout = req.getParameter("kmsout");
			String kmsin = req.getParameter("kmsin");
            String timeout = req.getParameter("timeout");
            String timein = req.getParameter("timein");
            boolean submit = Boolean.parseBoolean(req.getParameter("submit").toString());
            String reason = req.getParameter("reason");
            boolean isNoShow = Boolean.parseBoolean(req.getParameter("isNoShow").toString());
            boolean isCancelled = Boolean.parseBoolean(req.getParameter("isCancelled").toString());
            String cancelReason = req.getParameter("cancelReason");
            
            
            String reference = req.getParameter("reference");
            
            if(kmsin != null){
                
                String sql = "UPDATE transfer_assignments SET kms_in='" + kmsin + "', no_show = " + isNoShow + ",  no_show_reason = '" + reason + "' ,cancelled =  " + isCancelled + " , cancel_reason = '" + cancelReason + "'";
				if(kmsout != "") sql += ", closed=" + submit + ",  kms_out='" + kmsout + "'";
				if(!timeout.equals("")) sql += ", time_out = '" + timeout + "'::time ";
                if(!timein.equals("")) sql += ", time_in = '" + timein + "'::time ";

                sql +=  " WHERE transfer_assignment_id=" + reference + " AND driver_id=" + session.getAttribute("driver_id");

                if(doLog) log.info("SQL : " + sql);
                if(db.executeQuery(sql) == null){
                    success = 1; 
                    message = submit ? "Submited Successfully":"Saved Successfully";
                }else{
                    success = 0; 
                    message = submit ? "Submitting Failed. Please Try Again":"Saving Failed. Please Try Again";
                }
            }else{
                success = 0; message = "Error Saving Details";
            }
            
            if(db != null){
				db.close();
				if(doLog) log.info("Closing Connection --------------");
			}
			
			resp.setContentType("application/json");
			PrintWriter out = resp.getWriter();
			JSONObject jobj = new JSONObject();
			jobj.put("success", success);
			jobj.put("message", message);
            out.print(jobj);
            if(doLog) log.info("JSON  SAVE : " + jobj.toString());
        }
		
        
        else if(tag.equals("authenticate")){
			
			String dbconfig = "java:/comp/env/jdbc/database";
			BDB db = new BDB(dbconfig);log.info("Connection Opened--------------");
			int success = 0; String message = "Invalid Credentials";
			String mobile = req.getParameter("mobile");
			String pin = req.getParameter("pin");			
			
			if(mobile != null && mobile != "" && pin != null && pin != ""){	
				try{
					// update table orgs to have free_frield & show fare
					//ALTER TABLE orgs ADD show_fare boolean default false;
					//ALTER TABLE orgs ADD gds_free_field integer default 96;
					
					//select * from orgs
					
					String chkSql = "SELECT driver_id, driver_name,driver_pin FROM drivers WHERE mobile_number = '" + mobile + "' AND driver_pin = md5('" + pin + "')  LIMIT 1";
					log.info("SQL : " + chkSql);
                    
                    ResultSet rs = db.readQuery(chkSql);
					
					session.setAttribute("driver_id",null);
					session.setAttribute("driver_name",null);
					
					success = 0; message = "Invalid Mobile Number or Pin";
					
					while (rs.next()) {
                        
						session.setAttribute("driver_id",rs.getString("driver_id"));
						session.setAttribute("driver_name",rs.getString("driver_name"));
						
                        success = 1; message = "Authentication Successfull. Redirecting......";
					}
				}catch(SQLException e){
					log.severe("SQL ERROR : " + e.toString());
					success = 0;	message = "An Error Authenticating";
				}catch(NullPointerException ex){
					log.severe("NullPointerException : " + ex.toString());
					success = 0;	message = "An Error Authenticating";
				}
			}else{
				success = 0; message = "Permission Denied : Invalid Credentials ";
			}
			
			if(db != null){
				db.close();
				if(doLog) log.info("Closing Connection --------------");
			}
			
			
			resp.setContentType("application/json");
			PrintWriter out = resp.getWriter();
			JSONObject jobj = new JSONObject();
			jobj.put("success", success);
			jobj.put("message", message);
			out.print(jobj);
			if(doLog) log.info("JSON  VALIDATE USER : " + jobj.toString());
			
		}
        
        
        
        
        
        
	}//dopost
    
    
    
	
}
