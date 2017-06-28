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


@WebServlet("/processrequest")
public class ProcessRequestServlet extends HttpServlet{
	static Logger log = Logger.getLogger(ProcessRequestServlet.class.getName());
	RequestDispatcher dispatcher;
	
	@SuppressWarnings("unchecked")
	@Override
	public void doPost(HttpServletRequest req, HttpServletResponse resp)	throws ServletException, IOException {
		HttpSession session = req.getSession(false);
		String tag = req.getParameter("tag");
		if(tag.equals("") || tag == null){
			dispatcher = req.getRequestDispatcher("consultant/");
			dispatcher.forward(req, resp);
		}
		
		
		else if(tag.equals("cars") || tag.equals("payment") || tag.equals("currency") || tag.equals("cust_code") || tag.equals("booking_location")){
			log.info("Loading Dropdown " + tag + "....................");
			JSONObject jobj = new JSONObject();
			JSONArray jArray = new JSONArray();
			String dbconfig = "java:/comp/env/jdbc/database"; //dbconfig = "java:/comp/env/jdbc/databaseOracle";
            //if(tag.equals("payment"))dbconfig = "java:/comp/env/jdbc/database";
            
			BDB db = new BDB(dbconfig);
			
			String sql = "";
			if(tag.equals("cars")){
				sql = "SELECT car_type_code, car_type_name FROM car_types ORDER BY car_type_name";
			}else if(tag.equals("payment")){
				sql = "SELECT payment_type_id, payment_type_name FROM payment_types ORDER BY payment_type_name";
			}else if(tag.equals("currency")){
				sql = "SELECT currency_symbol, ((currency_symbol || ' - ') || currency_name) AS currency" 
					  + " FROM currency  ORDER BY currency_symbol";
			}else if(tag.equals("cust_code")){
				sql = "SELECT customer_code, customer_name FROM customer_codes ORDER BY customer_name";
			}else if(tag.equals("booking_location")){
				sql = "SELECT location_code, location_name FROM locations ORDER BY location_name";
			}
            
			ResultSet rs = db.readQuery(sql);
			int success = 0; 
			String message = "No Options Available";
			try {
				while(rs.next()) {
					success = 1; message = "Options Available";
					JSONObject detail = new JSONObject();
					detail.put("id", rs.getString(1));
					detail.put("name", rs.getString(2));
					jArray.add(detail);
// 					if(tag.equals("payment")){
// 						log.info("\n" + rs.getString(1) + " : " + rs.getString(2));
// 					}
					
				}
				rs.close();				
			} catch (SQLException e) {
				log.info("SQLException : " + e.toString());
			}
			db.close();
			
			//log.info("\n Message : " + tag + " - " + message);
			jobj.put("success", success);			
	        jobj.put("message", message);
	        jobj.put("array", jArray);
			resp.setContentType("application/json");
			PrintWriter out = resp.getWriter();
	        out.print(jobj);
			
		}//dropdown
		
        
        if(tag.equals("authenticate")){
			log.info("authenticate --------------");
			String dbconfig = "java:/comp/env/jdbc/database";
			BDB db = new BDB(dbconfig);log.info("Connection Opened--------------");
			int success = 0; String message = "You Are Not Subscribed to this service.";
			String son = req.getParameter("son");
			String pcc = req.getParameter("pcc");	
            
            log.info("authenticate --------- son : " + son + "\npcc : " + pcc);
            
			if(son != null && son != "" && pcc != null && pcc != ""){	
				try{
					// update table orgs to have free_frield & show fare
					//ALTER TABLE orgs ADD show_fare boolean default false;
					//ALTER TABLE orgs ADD gds_free_field integer default 96;
					
					//select * from orgs
					
					String chkSql = "SELECT entitys.entity_id, entitys.org_id, entitys.son, entitys.entity_name, entitys.primary_email,  orgs.pcc, orgs.org_name FROM entitys INNER JOIN orgs ON orgs.org_id = entitys.org_id WHERE lower(entitys.son) = lower('" + son + "') AND lower(orgs.pcc) = lower('" + pcc+ "')  AND (entitys.is_active = true) LIMIT 1";
					log.info("SQL : " + chkSql);
                    
                    ResultSet rs = db.readQuery(chkSql);
					
					session.setAttribute("pcc",null);
					session.setAttribute("son",null);
					session.setAttribute("name", null);
					session.setAttribute("org", null);
					session.setAttribute("org_id", null);
					session.setAttribute("entity_id", null);
                    session.setAttribute("primary_email", null);
					
					success = 0; message = "You Are Not Subscribed to this service.";
					
					while (rs.next()) {
						session.setAttribute("pcc",pcc);
						session.setAttribute("son",son);
						session.setAttribute("name",rs.getString("entity_name"));
						session.setAttribute("org",rs.getString("org_name"));
						session.setAttribute("org_id", rs.getString("org_id"));
						session.setAttribute("entity_id", rs.getString("entity_id"));
						session.setAttribute("primary_email", rs.getString("primary_email"));
	
						/*log.info("USER : PCC : " + pcc 
						+ "\nSON : " + son 
						+ "\nNAME : " + rs.getString("entity_name") 
						+ "\nORG : " + rs.getString("org_name") 
						+ "\nORGID : " + rs.getString("org_id") 
						+ "\nENTITY_ID : " + rs.getString("entity_id"));
						*/
                        success = 1; message = "Authentication Successfull. Redirecting......";
					}
				}catch(SQLException e){
					log.severe("SQL ERROR : " + e.toString());
					success = 0;	message = "An Error Authenticating";
				}catch(NullPointerException ex){
					log.severe("SQL ERROR : " + ex.toString());
					success = 0;	message = "An Error Authenticating";
				}
			}else{
				success = 0; message = "Permission Denied : Invalid PCC and SON ";
			}
			
			if(db != null){
				db.close();
				log.info("Closing Connection --------------");
			}
			
			
			resp.setContentType("application/json");
			PrintWriter out = resp.getWriter();
			JSONObject jobj = new JSONObject();
			jobj.put("success", success);
			jobj.put("message", message);
			out.print(jobj);
			log.info("JSON  VALIDATE USER : " + jobj.toString());
			
		}
        
        
        
        
        
        
	}//dopost
	
}
