

import java.sql.DriverManager;
import java.sql.Connection;
import java.sql.Statement;
import java.sql.ResultSet;
import java.sql.SQLException;

import java.net.URL;
import java.net.MalformedURLException;
import babcock.ws.DataWebService;
import babcock.ws.DataWebServiceService;

public class umisRegistration {

	public static void main(String args[]) {
		umisRegistration ur = new umisRegistration();
		ur.registration();
	}
	
	public void registration() {
		try {
			URL wsURL = new URL("http://umis.babcock.edu.ng/babcock/webservice?wsdl");
			//URL wsURL = new URL("http://localhost:8080/babcock/webservice?wsdl");
		
			DataWebServiceService bws = new DataWebServiceService(wsURL);
			DataWebService port = bws.getDataWebServicePort();
			
			// Add the students
			addStudent(port);
						
		} catch (MalformedURLException ex) {
			System.out.println("URL access error : " + ex);
		}
	}	

	private void addStudent(DataWebService port) {
		try {
			String stSql = "SELECT registrationid, existingid, surname, firstname, othernames, ";
			stSql += "upper(substr('sex', 1, 1)) as nsex, upper(substr('maritalstatus', 1, 1)) as nmaritalstatus, ";
			stSql += "nationalityid, birthdate, ";
			stSql += "homeaddress, zipcode, town, birthstateid, ";
			stSql += "phonenumber, babcock_email, guardian, majorid, denominationid, ";
			stSql += "account_number, e_tranzact_no, first_password, entity_password ";
			stSql += "FROM registrations ";
			stSql += "WHERE is_newstudent = true and is_picked = false;";
			
			Connection db = DriverManager.getConnection("jdbc:postgresql://62.24.122.19/babcock", "root", "invent2k");
			Statement st = db.createStatement();
			ResultSet rs = st.executeQuery(stSql);
			String xml = null;
    	    while(rs.next()) {
				xml = "<TRANSFERS>\n";
				xml += "<TRANSFER name=\"App Students\" keyfield=\"app_student_id\" table=\"app_students\">\n";
				xml += "	<app_student_id>" + format(rs.getString("registrationid")) + "</app_student_id>\n";
				xml += "	<studentid>" + format(rs.getString("existingid")) + "</studentid>\n";
				xml += "	<surname>" + format(rs.getString("surname")) + "</surname>\n";
				xml += "	<firstname>" + format(rs.getString("firstname")) + "</firstname>\n";
				xml += "	<othernames>" + format(rs.getString("othernames")) + "</othernames>\n";
				xml += "	<sex>" + format(rs.getString("nsex")) + "</sex>\n";
				xml += "	<maritalstatus>" + format(rs.getString("nmaritalstatus")) + "</maritalstatus>\n";
				xml += "	<nationality>" + format(rs.getString("nationalityid")) + "</nationality>\n";
				xml += "	<birthdate>" + format(rs.getString("birthdate")) + "</birthdate>\n";
				
				xml += "	<address>" + format(rs.getString("homeaddress")) + "</address>\n";
				xml += "	<zipcode>" + format(rs.getString("zipcode")) + "</zipcode>\n";
				xml += "	<town>" + format(rs.getString("town")) + "</town>\n";
				xml += "	<stateid>" + format(rs.getString("birthstateid")) + "</stateid>\n";
				xml += "	<countrycodeid>" + format(rs.getString("nationalityid")) + "</countrycodeid>\n";
							
				xml += "	<mobile>" + format(rs.getString("phonenumber")) + "</mobile>\n";
				xml += "	<email>" + format(rs.getString("babcock_email")) + "</email>\n";
				
				xml += "	<guardianname>" + format(rs.getString("guardian")) + "</guardianname>\n";
				xml += "	<gaddress>" + format(rs.getString("homeaddress")) + "</gaddress>\n";
				xml += "	<gzipcode>" + format(rs.getString("zipcode")) + "</gzipcode>\n";
				xml += "	<gtown>" + format(rs.getString("town")) + "</gtown>\n";
				xml += "	<gcountrycodeid>" + format(rs.getString("nationalityid")) + "</gcountrycodeid>\n";
			
				xml += "	<majorid>" + format(rs.getString("majorid")) + "</majorid>\n";
				xml += "	<denominationid>" + format(rs.getString("denominationid")) + "</denominationid>\n";
				xml += "	<account_number>" + format(rs.getString("account_number")) + "</account_number>\n";
				xml += "	<e_tranzact_no>" + format(rs.getString("e_tranzact_no")) + "</e_tranzact_no>\n";
				xml += "	<first_password>" + format(rs.getString("first_password")) + "</first_password>\n";
				xml += "	<entity_password>" + format(rs.getString("entity_password")) + "</entity_password>\n";
				xml += "</TRANSFER>\n";
				xml += "</TRANSFERS>\n";
				
				// Writting data
				String resp = port.addWsData(xml, "test123");
				System.out.println("Add student data: \n" + resp);
				
				String updStr = "UPDATE registrations SET is_picked = true ";
				updStr += "WHERE registrationid = " + rs.getString("registrationid");
				Statement stUP = db.createStatement();
				stUP.executeUpdate(updStr);
				stUP.close();
			}
			rs.close();
			st.close();
			db.close();
    	} catch (SQLException ex) {
			System.out.println("Error in Query : " + ex.toString());
       	}
	}
	
	public String format(String in) {
		if(in == null) return "";
		return in.replace("<", "").replace(">", "").replace("\"", "").replace("'", "");
	}
}


