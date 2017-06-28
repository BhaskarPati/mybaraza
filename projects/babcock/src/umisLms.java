

import java.net.URL;
import java.net.MalformedURLException;
import babcock.ws.DataWebService;
import babcock.ws.DataWebServiceService;

public class umisLms {

	public static void main(String args[]) {
	
		try {
	
			URL wsURL = new URL("http://umis.babcock.edu.ng/babcock/webservice?wsdl");
		
			DataWebServiceService bws = new DataWebServiceService(wsURL);
			DataWebService port = bws.getDataWebServicePort();
			
			String resp = port.getWsData(getStudentRequest("06/0382", "9b16759a62899465ab21e2e79d2ef75c"), "test123");
			System.out.println("Reading student data: \n" + resp);
						
						
		} catch (MalformedURLException ex) {
			System.out.println("URL access error : " + ex);
		}

	}
	
	private static String getStudentRequest(String studentId, String password) {	
		String xml = "<QUERY>\n";
		xml += "<GRID name=\"student\" keyfield=\"studentid\" table=\"ws_students\" ";
		xml += " where=\"(studentid = '" + studentId + "') AND (entity_password = '" + password + "')\" >\n";
		xml += "	<TEXTFIELD>studentid</TEXTFIELD>\n";
		xml += "	<TEXTFIELD>firstname</TEXTFIELD>\n";
		xml += "	<TEXTFIELD>othernames</TEXTFIELD>\n";
		xml += "	<TEXTFIELD>surname</TEXTFIELD>\n";
		xml += "	<TEXTFIELD>birthdate</TEXTFIELD>\n";
		xml += "	<TEXTFIELD>mobile</TEXTFIELD>\n";
		xml += "	<TEXTFIELD>email</TEXTFIELD>\n";
		xml += "</GRID>\n";
		xml += "</QUERY>\n";
		
		return xml;
	}
	

}


