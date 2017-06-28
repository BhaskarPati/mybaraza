

import java.net.URL;
import java.net.MalformedURLException;
import babcock.ws.DataWebService;
import babcock.ws.DataWebServiceService;

public class umisRead {

	public static void main(String args[]) {
	
		try {
	
			URL wsURL = new URL("http://umis.babcock.edu.ng/babcock/webservice?wsdl");
		
			DataWebServiceService bws = new DataWebServiceService(wsURL);
			DataWebService port = bws.getDataWebServicePort();
			
			
			String resp = port.getWsData(getGrades(), "babcockWB12345");
			System.out.println("Reading grade data: \n" + resp);
			
			resp = port.getWsData(getMajors(), "babcockWB12345");
			System.out.println("Reading mjors data: \n" + resp);
			
			resp = port.getWsData(getSchools(), "babcockWB12345");
			System.out.println("Reading school data: \n" + resp);
			
			resp = port.getWsData(getDepartments(), "babcockWB12345");
			System.out.println("Reading department data: \n" + resp);
			
			resp = port.getWsData(getResidences(), "babcockWB12345");
			System.out.println("Reading residences data: \n" + resp);
			
			resp = port.getWsData(getSemesters(), "babcockWB12345");
			System.out.println("Reading residences data: \n" + resp);
			
			resp = port.getWsData(getStudentSemester("2016/2017.1", "ACCT"), "babcockWB12345");
			System.out.println("Reading residences data: \n" + resp);
			
			
			/*resp = port.getWsData(getHallService("15/1353"), "test123");
			System.out.println("Reading student data: \n" + resp);
			
			resp = port.getWsData(getStudentRequest("06/0382"), "test123");
			System.out.println("Reading student data: \n" + resp);
						
			resp = port.getWsData(getTimeTableRequest("06/0382"), "test123");
			System.out.println("Reading timetable data: \n" + resp);
			
			resp = port.getWsData(getGradeRequest("06/0382", "2009/2010.3"), "test123");
			System.out.println("Reading student data: \n" + resp);*/
						
		} catch (MalformedURLException ex) {
			System.out.println("URL access error : " + ex);
		}
	}
	
	private static String getGrades() {
		String xml = "<QUERY>\n";
		xml += "	<GRID name=\"Grades\" keyfield=\"gradeid\" table=\"grades\">\n";
		xml += "		<TEXTFIELD>minrange</TEXTFIELD>\n";
		xml += "		<TEXTFIELD>maxrange</TEXTFIELD>\n";
		xml += "		<TEXTFIELD>gradeweight</TEXTFIELD>\n";
		xml += "	</GRID>\n";
		xml += "</QUERY>\n";
				
		System.out.println("XML : " + xml);
		
		return xml;
	}
	
	private static String getMajors() {
		String xml = "<QUERY>\n";
		xml += "	<GRID name=\"Majors\" keyfield=\"majorid\" table=\"majors\">\n";
		xml += "		<TEXTFIELD>departmentid</TEXTFIELD>\n";
		xml += "		<TEXTFIELD>majorname</TEXTFIELD>\n";
		xml += "	</GRID>\n";
		xml += "</QUERY>\n";
				
		System.out.println("XML : " + xml);
		
		return xml;
	}
	
	private static String getSchools() {
		String xml = "<QUERY>\n";
		xml += "	<GRID name=\"Schools\" keyfield=\"schoolid\" table=\"schools\">\n";
		xml += "		<TEXTFIELD>schoolname</TEXTFIELD>\n";
		xml += "	</GRID>\n";
		xml += "</QUERY>\n";
				
		System.out.println("XML : " + xml);
		
		return xml;
	}

	private static String getDepartments() {
		String xml = "<QUERY>\n";
		xml += "	<GRID name=\"Departments\" keyfield=\"departmentid\" table=\"departments\">\n";
		xml += "		<TEXTFIELD>schoolid</TEXTFIELD>\n";
		xml += "		<TEXTFIELD>departmentname</TEXTFIELD>\n";
		xml += "	</GRID>\n";
		xml += "</QUERY>\n";
				
		System.out.println("XML : " + xml);
		
		return xml;
	}
	
	private static String getResidences() {
		String xml = "<QUERY>\n";
		xml += "	<GRID name=\"Residences\" keyfield=\"residenceid\" table=\"residences\">\n";
		xml += "		<TEXTFIELD>residencename</TEXTFIELD>\n";
		xml += "	</GRID>\n";
		xml += "</QUERY>\n";
				
		System.out.println("XML : " + xml);
		
		return xml;
	}
	
	private static String getSemesters() {
		String xml = "<QUERY>\n";
		xml += "	<GRID name=\"Semesters\" keyfield=\"quarterid\" table=\"quarters\">\n";
		xml += "		<TEXTFIELD>qstart</TEXTFIELD>\n";
		xml += "		<TEXTFIELD>active</TEXTFIELD>\n";
		xml += "		<TEXTFIELD>publishgrades</TEXTFIELD>\n";
		xml += "	</GRID>\n";
		xml += "</QUERY>\n";
				
		System.out.println("XML : " + xml);
		
		return xml;
	}	
	
	private static String getStudentSemester(String quarterId, String majorId) {
		String xml = "<QUERY>\n";
		xml += "<GRID name=\"Semester Student List\" keyfield=\"qstudentid\" table=\"ws_qstudents\" ";
		xml += "where=\"quarterid = '" + quarterId + "' AND majorid = '" +  majorId + "'\">\n";
		xml += "	<TEXTFIELD>quarterid</TEXTFIELD>\n";
		xml += "	<TEXTFIELD>studentid</TEXTFIELD>\n";
		xml += "	<TEXTFIELD>studentname</TEXTFIELD>\n";
		xml += "	<TEXTFIELD>quarterid</TEXTFIELD>\n";
		xml += "	<TEXTFIELD>schoolid</TEXTFIELD>\n";
		xml += "	<TEXTFIELD>departmentid</TEXTFIELD>\n";
		xml += "	<TEXTFIELD>studylevel</TEXTFIELD>\n";
		xml += "	<TEXTFIELD>majorid</TEXTFIELD>\n";
		xml += "	<TEXTFIELD>majorname</TEXTFIELD>\n";
		xml += "	<TEXTFIELD>residenceid</TEXTFIELD>\n";
		xml += "	<TEXTFIELD>finaceapproval</TEXTFIELD>\n";
		xml += "</GRID>\n";
		xml += "</QUERY>\n";
		
		System.out.println("XML : " + xml);
		
		return xml;
	}

	
	private static String getHallService(String studentId) {	
		String xml = "<QUERY>\n";
		xml += "<GRID name=\"Hall Service\" keyfield=\"studentid\" table=\"ws_hall_service\" where=\"studentid = '" + studentId + "'\">\n";
		xml += "	<TEXTFIELD>studentid</TEXTFIELD>\n";
		xml += "	<TEXTFIELD>studentname</TEXTFIELD>\n";
		xml += "	<TEXTFIELD>quarterid</TEXTFIELD>\n";
		xml += "	<TEXTFIELD>schoolid</TEXTFIELD>\n";
		xml += "	<TEXTFIELD>departmentid</TEXTFIELD>\n";
		xml += "	<TEXTFIELD>studylevel</TEXTFIELD>\n";
		xml += "	<TEXTFIELD>majorid</TEXTFIELD>\n";
		xml += "	<TEXTFIELD>majorname</TEXTFIELD>\n";
		xml += "	<TEXTFIELD>residenceid</TEXTFIELD>\n";
		xml += "	<TEXTFIELD>finaceapproval</TEXTFIELD>\n";
		xml += "</GRID>\n";
		xml += "</QUERY>\n";
		
		System.out.println("XML : " + xml);
		
		return xml;
	}
	
	private static String getFoodService(String studentId) {	
		String xml = "<QUERY>\n";
		xml += "<GRID name=\"Food Service\" keyfield=\"studentid\" table=\"ws_food_service\" where=\"studentid = '" + studentId + "'\">\n";
		xml += "	<TEXTFIELD>studentid</TEXTFIELD>\n";
		xml += "	<TEXTFIELD>studentname</TEXTFIELD>\n";
		xml += "	<TEXTFIELD>mealtype</TEXTFIELD>\n";
		xml += "	<TEXTFIELD>studylevel</TEXTFIELD>\n";
		xml += "	<TEXTFIELD>majorid</TEXTFIELD>\n";
		xml += "	<TEXTFIELD>majorname</TEXTFIELD>\n";
		xml += "</GRID>\n";
		xml += "</QUERY>\n";
		
		System.out.println("XML : " + xml);
		
		return xml;
	}
	
	private static String getStudentRequest(String studentId) {	
		String xml = "<QUERY>\n";
		xml += "<GRID name=\"student\" keyfield=\"studentid\" table=\"ws_students\" where=\"studentid = '" + studentId + "'\">\n";
		xml += "	<TEXTFIELD>studentid</TEXTFIELD>\n";
		xml += "	<TEXTFIELD>firstname</TEXTFIELD>\n";
		xml += "	<TEXTFIELD>othernames</TEXTFIELD>\n";
		xml += "	<TEXTFIELD>surname</TEXTFIELD>\n";
		xml += "	<TEXTFIELD>birthdate</TEXTFIELD>\n";
		xml += "	<TEXTFIELD>mobile</TEXTFIELD>\n";
		xml += "	<TEXTFIELD>email</TEXTFIELD>\n";
		xml += "</GRID>\n";
		xml += "</QUERY>\n";
		
		System.out.println("XML : " + xml);
		
		return xml;
	}
	
	private static String getTimeTableRequest(String studentId) {	
		String xml = "<QUERY>\n";
		xml += "<GRID name=\"Timetable\" table=\"ws_student_timetable\" where=\"studentid = '" + studentId + "'\">\n";
		xml += "		<TEXTFIELD>starttime</TEXTFIELD>\n";
		xml += "		<TEXTFIELD>endtime</TEXTFIELD>\n";
		xml += "		<TEXTFIELD>cmonday</TEXTFIELD>\n";
		xml += "		<TEXTFIELD>ctuesday</TEXTFIELD>\n";
		xml += "		<TEXTFIELD>cwednesday</TEXTFIELD>\n";
		xml += "		<TEXTFIELD>cthursday</TEXTFIELD>\n";
		xml += "		<TEXTFIELD>cfriday</TEXTFIELD>\n";
		xml += "		<TEXTFIELD>csunday</TEXTFIELD>\n";
		xml += "		<TEXTFIELD>lab</TEXTFIELD>\n";
		xml += "		<TEXTFIELD>lab</TEXTFIELD>\n";
		xml += "		<TEXTFIELD>courseid</TEXTFIELD>\n";
		xml += "		<TEXTFIELD>coursetitle</TEXTFIELD>\n";
		xml += "		<TEXTFIELD>instructorname</TEXTFIELD>\n";
		xml += "		<TEXTFIELD>classoption</TEXTFIELD>\n";
		xml += "		<TEXTFIELD>assetname</TEXTFIELD>\n";
		xml += "		<TEXTFIELD>location</TEXTFIELD>\n";
		xml += "		<TEXTFIELD>building</TEXTFIELD>\n";
		xml += "	</GRID>\n";
		xml += "</QUERY>\n";
		
		return xml;
	}
	
	private static String getGradeRequest(String studentId, String semsterId) {	
		String xml = "<QUERY>\n";
		xml += "	<GRID name=\"Grades\" keyfield=\"qstudentid\" table=\"ws_student_grades\" ";
		xml += "where=\"(studentid = '" + studentId + "') AND (quarterid = '" + semsterId + "')\">\n";
		xml += "		<TEXTFIELD>quarterid</TEXTFIELD>\n";
		xml += "		<TEXTFIELD>StudyLevel</TEXTFIELD>\n";
		xml += "		<TEXTFIELD>credit</TEXTFIELD>\n";
		xml += "		<TEXTFIELD>gpa</TEXTFIELD>\n";
		xml += "		<TEXTFIELD>cummcredit</TEXTFIELD>\n";
		xml += "		<TEXTFIELD>cummgpa</TEXTFIELD>\n";
		xml += "	</GRID>\n";
		xml += "</QUERY>\n";
		
		System.out.println("XML : " + xml);
		
		return xml;
	}

}


