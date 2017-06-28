import java.io.IOException;
import java.io.PrintWriter;

import java.sql.ResultSet;
import java.sql.SQLException;

import javax.servlet.annotation.WebServlet;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import java.util.Map;
import java.util.HashMap;
import java.util.ArrayList;
import java.util.logging.Logger;

import org.baraza.xml.BXML;
import org.baraza.xml.BElement;
import org.baraza.DB.BDB;
import org.baraza.DB.BQuery;

import org.json.simple.JSONArray;
import org.json.simple.JSONObject;

@WebServlet("/processpnr")
public class ProcessPNRXML extends HttpServlet{
	static Logger log = Logger.getLogger(ProcessPNRXML.class.getName());
	@SuppressWarnings("unchecked")
	@Override
	public void doPost(HttpServletRequest req, HttpServletResponse rsp)	throws ServletException, IOException {
		log.info("Processing PNR .............");
		String xml_string = null;
		xml_string = req.getParameter("pnr_xml");
		log.info("PNR XML : " + xml_string);
		
		
		
		Map<String, String> lName = new HashMap<String, String>(); 
		Map<String, String> fName = new HashMap<String, String>();
		Map<String, String> phonInfo = new HashMap<String, String>();
		
		//list for all segments
		//ArrayList<HashMap<String, String>> airSegments = new ArrayList<HashMap<String, String>>();
		JSONArray airSegments = new JSONArray();
		
		if(!xml_string.isEmpty() && xml_string != null){
			BElement root = new BXML(xml_string, true).getRoot().getElementByName("PNRBFRetrieve");
			//System.out.println(root.toString());
			
			
            
			//get sg details
			
			for(BElement el : root.getElements()) {
				String elName = el.getName();
				if(elName == null) elName = "";
				
				System.out.println("EL NAME : " + elName);
				if(elName.equals("LNameInfo")) {
					lName.put(el.getElementByName("LNameNum").getValue(), el.getElementByName("LName").getValue());
				}
				if(elName.equals("FNameInfo")) {
					fName.put(el.getElementByName("AbsNameNum").getValue(), el.getElementByName("FName").getValue());
				}
				
				if(elName.equals("PhoneInfo")) {
					phonInfo.put(el.getElementByName("PhoneFldNum").getValue(), el.getElementByName("Phone").getValue());
				}
				
				if(elName.equals("AirSeg")) {
					//HashMap<String, String> airSeg = new HashMap<String, String>();
					JSONObject airSeg = new JSONObject();
					
					airSeg.put("SegNum", el.getElementByName("SegNum").getValue());					
					airSeg.put("AirV", el.getElementByName("AirV").getValue());
					airSeg.put("FltNum", el.getElementByName("FltNum").getValue());
					airSeg.put("StartAirp", el.getElementByName("StartAirp").getValue());
					airSeg.put("EndAirp", el.getElementByName("EndAirp").getValue());
					airSeg.put("StartTm", formatTime(el.getElementByName("StartTm").getValue()));
					airSeg.put("EndTm", formatTime(el.getElementByName("EndTm").getValue()));
					airSeg.put("Dt", formatDate(el.getElementByName("Dt").getValue()));
					
					airSegments.add(airSeg);
				}
				
			}
			
			
			JSONArray names = new JSONArray();
			
			for (String nKey : lName.keySet()) {
				JSONObject name = new JSONObject();
				name.put("key", nKey);
				name.put("name", lName.get(nKey) + " " + fName.get(nKey) );
				names.add(name);
			}
			
			
			JSONArray phones = new JSONArray();;
			
			for (String nKey : phonInfo.keySet()) {
				JSONObject phone = new JSONObject();
				String p = phonInfo.get(nKey);
				phone.put("key", nKey);
				phone.put("phone", formatPhonenumber(p.substring((p.indexOf("*")) + 1)));
				phones.add(phone);
			}
			
			//=======================================================================
			log.info("Post Process PNR ");
			
			rsp.setContentType("application/json");
			PrintWriter out = rsp.getWriter();
			JSONObject jobj=new JSONObject();
			jobj.put("success", 1);
            jobj.put("segments", airSegments);
            jobj.put("phones", phones);
            jobj.put("names", names);
            jobj.put("message", "PNR Processed Successfully");
            out.print(jobj);
            System.out.println("JSON " + jobj.toString());
           
		}else{
			rsp.setContentType("application/json");
			PrintWriter out = rsp.getWriter();
			JSONObject jobj=new JSONObject();
			jobj.put("success", 0);
			jobj.put("message", "PNR Sent Was Empty");
			out.print(jobj);
		} 
	}
	
	private String formatDate(String s){
		String d = s.substring(0,4)  + "-" + s.substring(4,6) + "-" + s.substring(6,8)  ;
		return d;
	}
	private String formatTime(String s){
		if(s.length() == 3){
			s = "0" + s;
		}
		String d = s.substring(0,2) + ":" + s.substring(2,4);
		return d;
	}
	
	private String formatPhonenumber(String s){
		String d = "";
		if(s.substring(0,1).equals("0")){
			d = "254" + s.substring(1);
		}
		return d;
	}
	
	
}
