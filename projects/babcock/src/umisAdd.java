
import java.util.Date;
import java.net.URL;
import java.net.MalformedURLException;
import babcock.ws.DataWebService;
import babcock.ws.DataWebServiceService;

public class umisAdd {

	public static void main(String args[]) {
	
		try {
		
			System.out.println("Start Time : " + new Date());
	
			URL wsURL = new URL("http://umis.babcock.edu.ng/babcock/webservice?wsdl");
		
			DataWebServiceService bws = new DataWebServiceService(wsURL);
			DataWebService port = bws.getDataWebServicePort();
			
			// Writting data
			String resp = port.addWsData(addGrade(), "babcockWB12345");
			System.out.println("Add Citizenship Grade : \n" + resp);
			
			System.out.println("End Time : " + new Date());
			
		} catch (MalformedURLException ex) {
			System.out.println("URL access error : " + ex);
		}

	}
	
	private static String addGrade() {
		String xml = "<TRANSFERS>\n";
		xml += "	<TRANSFER name=\"Citizenship Grade\" keyfield=\"import_grade_id\" table=\"import_grades\">\n";
		xml += "		<import_grade_id>1001</import_grade_id>\n";
		xml += "		<course_id>GEDS001</course_id>\n";
		xml += "		<session_id>2016/2017.1</session_id>\n";
		xml += "		<student_id>12/1234</student_id>\n";
		xml += "		<score>87</score>\n";
		xml += "	</TRANSFER>\n";
		xml += "</TRANSFERS>\n";
		
		System.out.println("XML : " + xml);
		
		return xml;
	}

	private static String addStudent() {
		String xml = "<TRANSFERS>\n";
		xml += "<TRANSFER name=\"App Students\" keyfield=\"app_student_id\" table=\"app_students\">\n";
		xml += "	<app_student_id title=\"Application ID\">232</app_student_id>\n";
		xml += "	<surname title=\"Surname\">Gichangi</surname>\n";
		xml += "	<firstname title=\"Firstname\">Dennis</firstname>\n";
		xml += "	<othernames title=\"Othernames\">Wachira</othernames>\n";
		xml += "	<sex title=\"Gender\">M</sex>\n";
		xml += "	<nationality title=\"Nationality\">NG</nationality>\n";
		xml += "	<maritalstatus title=\"Marital Status\">S</maritalstatus>\n";
		xml += "	<birthdate title=\"Birth Date\">1979-03-29</birthdate>\n";
		xml += "	<bloodgroup title=\"Blood Group\">O+</bloodgroup>\n";
		xml += "	<address title=\"Address\">15th Street, Kaluna</address>\n";
		xml += "	<zipcode title=\"Zip Code\">3454</zipcode>\n";
		xml += "	<town title=\"Town\">Ilishan-Remo</town>\n";
		xml += "	<countrycodeid title=\"Country code\">NG</countrycodeid>\n";
		xml += "	<state_name title=\"State name\">Lagos</state_name>\n";
		xml += "	<telno title=\"Telephone Number\">2353425</telno>\n";
		xml += "	<mobile title=\"Mobile Number\">2353425</mobile>\n";
		xml += "	<email title=\"Email\">dennis@dennis.me.ke</email>\n";
		xml += "	<guardianname title=\"Guardian Name\">Geofrey Gichangi</guardianname>\n";
		xml += "	<gaddress title=\"Gaddress\">15th Street, Kaluna</gaddress>\n";
		xml += "	<gzipcode title=\"Gzipcode\">3454</gzipcode>\n";
		xml += "	<gtown title=\"Gtown\">Ilishan-Remo</gtown>\n";
		xml += "	<gcountrycodeid title=\"Gcountrycodeid\">NG</gcountrycodeid>\n";
		xml += "	<gtelno title=\"Gtelno\">324234</gtelno>\n";
		xml += "	<gemail title=\"Gemail\">ggichangi@hjhjh.com</gemail>\n";
		xml += "	<denomination_name title=\"Denominationid\">SDA</denomination_name>\n";
		xml += "	<departmentid title=\"Departmentid\">ACCT</departmentid>\n";
		xml += "	<degree_name title=\"Degree Name\">BSC</degree_name>\n";
		xml += "	<programme_name title=\"Programme Name\">Computer Science</programme_name>\n";
		xml += "</TRANSFER>\n";
		xml += "</TRANSFERS>\n";
		
		return xml;
	}
	

}


