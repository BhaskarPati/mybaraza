

import java.net.URL;
import java.net.MalformedURLException;
import org.baraza.web.BWebServiceService;
import org.baraza.web.BWebService;

public class umisMA {

	public static void main(String args[]) {
	
		try {
			URL wsURL = new URL("http://demo.dewcis.com/ueab/webservice?wsdl");
		
			BWebServiceService bws = new BWebServiceService(wsURL);
			BWebService port = bws.getBWebServicePort();

			String resp = port.getWsData(getStudentRequest("SKANME1421"), "test123");
			System.out.println("Reading student data: \n" + resp);
			
			resp = port.getWsData(getStudentRequest("SKANME1421", "b6f0038dfd42f8aa6ca25354cd2e3660"), "test123");
			System.out.println("Reading student data: \n" + resp);
		} catch (MalformedURLException ex) {
			System.out.println("URL access error : " + ex);
		}

	}

	private static String getStudentRequest(String studentId) {	
		String xml = "<QUERY>\n";
		xml += "<GRID name=\"student\" keyfield=\"studentid\" table=\"ws_students\" ";
		xml += " where=\"(studentid = '" + studentId + "') \" >\n";
		xml += "	<TEXTFIELD>studentid</TEXTFIELD>\n";
		xml += "	<TEXTFIELD>studentname</TEXTFIELD>\n";
		xml += "	<TEXTFIELD>birthdate</TEXTFIELD>\n";
		xml += "	<TEXTFIELD>email</TEXTFIELD>\n";
		xml += "	<TEXTFIELD>departmentid</TEXTFIELD>\n";
		xml += "	<TEXTFIELD>sex</TEXTFIELD>\n";
		xml += "	<TEXTFIELD>nationality</TEXTFIELD>\n";
		xml += "	<TEXTFIELD>address</TEXTFIELD>\n";
		xml += "	<TEXTFIELD>town</TEXTFIELD>\n";
		xml += "	<TEXTFIELD>telno</TEXTFIELD>\n";
		xml += "</GRID>\n";
		xml += "</QUERY>\n";
		
		return xml;
	}
	
	private static String getStudentRequest(String studentId, String password) {	
		String xml = "<QUERY>\n";
		xml += "<GRID name=\"student\" keyfield=\"studentid\" table=\"ws_qstudents\" ";
		xml += " where=\"(studentid = '" + studentId + "') AND (entity_password = '" + password + "')\" >\n";
		xml += "	<TEXTFIELD>studentid</TEXTFIELD>\n";
		xml += "	<TEXTFIELD>studentname</TEXTFIELD>\n";
		xml += "	<TEXTFIELD>birthdate</TEXTFIELD>\n";
		xml += "	<TEXTFIELD>email</TEXTFIELD>\n";
		xml += "	<TEXTFIELD>departmentid</TEXTFIELD>\n";
		xml += "	<TEXTFIELD>quarterid</TEXTFIELD>\n";
		xml += "	<TEXTFIELD>org_name</TEXTFIELD>\n";
		xml += "	<TEXTFIELD>sex</TEXTFIELD>\n";
		xml += "	<TEXTFIELD>nationality</TEXTFIELD>\n";
		xml += "	<TEXTFIELD>address</TEXTFIELD>\n";
		xml += "	<TEXTFIELD>town</TEXTFIELD>\n";
		xml += "	<TEXTFIELD>telno</TEXTFIELD>\n";
		xml += "	<TEXTFIELD>residenceid</TEXTFIELD>\n";
		xml += "	<TEXTFIELD>residencename</TEXTFIELD>\n";
		xml += "</GRID>\n";
		xml += "</QUERY>\n";
		
		return xml;
	}
	

}


