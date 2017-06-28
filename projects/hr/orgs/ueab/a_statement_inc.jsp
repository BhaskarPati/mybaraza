
<%		

	String userIP = request.getRemoteAddr();
	String userName = request.getRemoteUser();

	BElement root = web.getRoot();

	String access = "UEABACCESS2012";
	String accountno = userName;

	DecimalFormat dfm = new DecimalFormat("###,###,###,###.00");
	SimpleDateFormat dbDatefm = new SimpleDateFormat("yyyy-MM-dd");
	SimpleDateFormat dsDatefm = new SimpleDateFormat("dd-MMM-yyyy");

	Calendar rightNow = Calendar.getInstance();
	String currdate = dsDatefm.format(rightNow.getTime());
	rightNow.add(Calendar.MONTH, -6);
	rightNow.set(Calendar.DAY_OF_MONTH, 1) ;
	String pastdate = dbDatefm.format(rightNow.getTime());

	String html = "<div class='ui-widget ui-widget-content ui-corner-all form_content'>\n";
	html += "<h3>Statement of account from " + dsDatefm.format(rightNow.getTime()) + " to " + currdate + "</h3>\n";
	html += "<table class='grid' cellpadding='0' cellspacing='0' align='center' width='950'>\n";
	try {
		String driver = "com.microsoft.sqlserver.jdbc.SQLServerDriver";
		String dbpath = "jdbc:sqlserver://192.168.3.10;database=SUNPLUSADV;user=online;password=Invent2k;";
		Class.forName(driver);
		Connection db = DriverManager.getConnection(dbpath, "online", "Invent2k");

		html += "\n<thead>\n<tr>\n";
		html += "\n<th data-field='Date'><b>Date</b></th>\n";
		html += "\n<th data-field='Journal'><b>Journal</b></th>\n";
		html += "\n<th data-field='Number'><b>Number</b></th>\n";
		html += "\n<th data-field='Reference'><b>Reference</b></th>";
		html += "\n<th data-field='Description'><b>Description</b></th>\n";
		html += "\n<th data-field='Debit'><b>Debit</b></th>\n";
		html += "\n<th data-field='Credit'><b>Credit</b></th>\n";
		html += "\n<th data-field='Balance'><b>Balance</b></th>";
		html += "\n</tr>\n</thead>";

		Float ob = new Float(0);
		String mysql = "SELECT SUM(AMOUNT) as ob FROM EDU_A_SALFLDG ";
		mysql += "WHERE (ACCNT_CODE = '" + accountno + "') AND (TRANS_DATETIME < '" + pastdate + "')";
		Statement st1 = db.createStatement(ResultSet.TYPE_SCROLL_SENSITIVE, ResultSet.CONCUR_UPDATABLE);
		ResultSet rs1 = st1.executeQuery(mysql);
		if(rs1.next()) ob = rs1.getFloat("ob") * -1;
		rs1.close();
		st1.close();
		//System.out.println("Opening Balance : " + dfm.format(ob));

		mysql = "SELECT * FROM EDU_A_SALFLDG ";
		mysql += "WHERE (ACCNT_CODE = '" + accountno + "') AND (TRANS_DATETIME >= '" + pastdate + "')";
		mysql += "ORDER BY TRANS_DATETIME";
		Statement st = db.createStatement(ResultSet.TYPE_SCROLL_SENSITIVE, ResultSet.CONCUR_UPDATABLE);
		ResultSet rs = st.executeQuery(mysql);

		html += "\n<tr><td></td><td></td><td></td><td></td><td><b>Opening Balance</b></td>";
		if(ob>0) html += "<td>" + dfm.format(ob) + "</td><td></td><td>" + dfm.format(ob) + "</td></tr>";
		else html += "<td></td><td>" + dfm.format(ob*-1) + "</td><td>" + dfm.format(ob * -1) + " Cr</td></tr>";

		String periodid = "";
		while (rs.next()) {
			if(!periodid.equals(rs.getString("PERIOD"))) {
				if(!periodid.equals("")) {
					html += "\n<tr><td></td><td></td><td></td><td></td><td><b>Opening Balance " + periodid + "</b></td>";
					if(ob > 0) html += "<td></td><td></td><td>" + dfm.format(ob) + "</td></tr>";
					else html += "<td></td><td></td><td>" + dfm.format(ob * -1) + " Cr</td></tr>";
				}

				periodid = rs.getString("PERIOD");
			}

			String jv = rs.getString("JRNAL_TYPE").trim() + String.format("%012d", rs.getInt("JRNAL_NO"));
			String txDate = dsDatefm.format(rs.getDate("TRANS_DATETIME"));
			Float amt = rs.getFloat("AMOUNT") * -1;
			ob += amt;

			html += "\n<tr><td>" + txDate + "</td><td>" + jv  + "</td><td>" + rs.getString("JRNAL_LINE");
			html += "</td><td>" + rs.getString("TREFERENCE") + "</td><td>" + rs.getString("DESCRIPTN");
			if(amt > 0) html += "<td>" + dfm.format(amt) + "</td><td></td>";
			else html += "<td></td><td>" + dfm.format(amt * -1) + "</td>";
			if(ob > 0) html += "<td>" + dfm.format(ob) + "</td></tr>";
			else html += "<td>" + dfm.format(ob * -1) + " Cr</td></tr>";
		}
		
		rs.close();
		st.close();
		db.close();
	} catch (ClassNotFoundException ex) {
		System.out.println("Class not found : " + ex);
	} catch (SQLException ex) {
		System.out.println("Database connection error : " + ex);
	}
	html += "\n</table>\n</div>";

	if(!"UEABACCESS2012".equals(access)) html = "<div class='ui-widget ui-widget-content ui-corner-all form_content'>\n</div>\n";
%>

	
	<section id="content">
		<%= html %>
	</section>


