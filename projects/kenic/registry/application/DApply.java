package dewcis.application;

import javax.servlet.*;
import javax.servlet.http.*;

import java.io.IOException;
import java.io.PrintWriter;
import java.util.List;
import java.util.Enumeration;

import dewcis.DB.DDB;
import dewcis.DB.DTable;

public class DApply extends HttpServlet {
	
	public void doPost(HttpServletRequest request, HttpServletResponse response)  {
		doGet(request, response);
	}

	public void doGet(HttpServletRequest request, HttpServletResponse response) {
	    response.setContentType("text/html");
		PrintWriter out =  null;

		DDB db = new DDB();
		db.openDatabase();

		try {
			out = response.getWriter();
		} catch (IOException ex) {
			System.out.println("IO Error : " + ex);
		}
		
		String submit = request.getParameter("submit");
		String applicantid = "";

		if(submit != null) applicantid = saveForm(db, request);

		try {
			request.getRequestDispatcher("application.jsp?display="+ applicantid).forward(request, response);
		} catch (Exception ex) {
			ex.printStackTrace();
		}

		db.closeDatabase();
	}

	public String saveForm(DDB db, HttpServletRequest request) {
		String remoteip = request.getRemoteAddr();
		String mysql = "";
	
		Enumeration params = request.getParameterNames();
		while(params.hasMoreElements()) {
			String param = (String)params.nextElement();
			String rqst = request.getParameter(param);
			if(param.equals("submit")) rqst = "";
			else mysql += ", " + param;

			if(!rqst.equals("")) {
				System.out.println(param + " : " + request.getParameter(param));
			}
		}
		mysql = "SELECT applicantid, ipaddress" + mysql;
		mysql += " FROM applicants";
		mysql += " WHERE applicantid is null";

		System.out.println(mysql);

		DTable table = new DTable(db.getDatabase(), mysql);
		table.recAdd();

		Enumeration aparams = request.getParameterNames();
		while(aparams.hasMoreElements()) {
			String param = (String)aparams.nextElement();
			String rqst = request.getParameter(param);

			if(rqst == null) rqst = "";

			if(!param.equals("submit")) {
				table.updateRow(param, rqst);
			}
		}
		table.updateRow("ipaddress", remoteip);

		String applicantid = table.recUpdate(db.getDatabase(), "applicants", "applicantid");
		
		return applicantid;
	}

}
