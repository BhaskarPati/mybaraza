import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.awt.BorderLayout;
import javax.swing.*;
import javax.xml.parsers.*;
import org.w3c.dom.*;

import java.io.InputStream;
import java.io.ByteArrayInputStream;
import java.lang.Long;
import java.lang.Integer;
import java.lang.NumberFormatException;
import java.text.DateFormat;
import java.text.ParseException;
import java.text.SimpleDateFormat;

import java.util.Calendar;
import java.util.List;
import java.util.ArrayList;
import java.util.Map;
import java.util.HashMap;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.Statement;
import java.sql.ResultSet;
import java.sql.SQLException;

import netscape.javascript.*;

public class tickets extends JApplet implements ActionListener {
	JTextArea ta1;
	
	JSpinner startDate, noOfDays;
	
	JButton b1;
	Connection db;
	String mydate;
	String agencypcc;
	String currency;
	boolean process_logs = false;
	public String value;

	public void init() {		// Run an applet
		connectdb(getParameter("db"), getParameter("dbuser"), getParameter("dbpasswd"));

		JPanel panel = new JPanel(new BorderLayout());
		JPanel buttonPanel = new JPanel();
		
		ta1 = new JTextArea(5, 30);
		JScrollPane sp1 = new JScrollPane(ta1);
		panel.add(sp1, BorderLayout.CENTER);
		
		SpinnerModel dateModel = new SpinnerDateModel();
		startDate = new JSpinner(dateModel);
		startDate.setEditor(new JSpinner.DateEditor(startDate, "dd-MMM-yyyy"));
		
		SpinnerModel numberModel = new SpinnerNumberModel(1, 1, 15, 1);
		noOfDays = new JSpinner(numberModel);

		b1 = new JButton("Run");;
		b1.addActionListener(this);
		buttonPanel.add(startDate);
		buttonPanel.add(noOfDays);
		buttonPanel.add(b1);
		panel.add(buttonPanel, BorderLayout.PAGE_END);
		
		getContentPane().add(panel);
	}
	
	public void actionPerformed(ActionEvent e) {
		if ("Run".equals(e.getActionCommand())) {
			ta1.setText("Hello");
			
			runJS();
		}
	}
	
	public void runJS() {
		try {
			JSObject window = JSObject.getWindow(this);
						
			// invoke JavaScript function
			String xmlPCC = (String) window.eval("getPCC()");
			List<String> pccList = getPcc(xmlPCC);
			
			int dayCount = ((SpinnerNumberModel)noOfDays.getModel()).getNumber().intValue();
			
			Calendar myDay = Calendar.getInstance();			
			myDay.setTime(((SpinnerDateModel)startDate.getModel()).getDate());
			
			for(int j = 0; j < dayCount; j++) {
				SimpleDateFormat sdfa = new SimpleDateFormat("ddMMM");
				String ticketDate = sdfa.format(myDay.getTime());
				ticketDate = ticketDate.toUpperCase();
				
				SimpleDateFormat sdfb = new SimpleDateFormat("yyyy-MM-dd");
				mydate = sdfb.format(myDay.getTime());;
				
				String xmlHMPR = "";
				String ticketList = "";
				String xmlTE = "";
				
				for(String pcc : pccList) {
					agencypcc = pcc;
					currency = "KES";
System.out.println("getHMPR('" + pcc + "', '" + ticketDate + "', 'KES')");
					xmlHMPR = (String) window.eval("getHMPR('" + pcc + "', '" + ticketDate + "', 'KES')");
					ticketList = makehmpr(xmlHMPR);
					if(ticketList.length() > 5) {
System.out.println("getTE('" + pcc + "', '" + ticketList + "')");
						xmlTE = (String) window.eval("getTE('" + pcc + "', '" + ticketList + "')");
						String[] kte = xmlTE.split("####");
						for(int i = 0; i < kte.length; i++) makete(kte[i]);
					}
					
					currency = "USD";
System.out.println("getHMPR('" + pcc + "', '" + ticketDate + "', 'USD')");
					xmlHMPR = (String) window.eval("getHMPR('" + pcc + "', '" + ticketDate + "', 'USD')");
					ticketList = makehmpr(xmlHMPR);
					if(ticketList.length() > 5) {
System.out.println("getTE('" + pcc + "', '" + ticketList + "')");
						xmlTE = (String) window.eval("getTE('" + pcc + "', '" + ticketList + "')");
						String[] ute = xmlTE.split("####");
						for(int i = 0; i < ute.length; i++) makete(ute[i]);
					}
				}
			
				// Process the segments
				processsegs();
				
				// number of days to add
				myDay.add(Calendar.DATE, 1);  
			}
		} catch (JSException jse) {
			jse.printStackTrace();
        }
	}

	public void connectdb(String dbpath, String dbuser, String dbpasswd) {
		try {
			String driver = "org.postgresql.Driver";
			Class.forName(driver);
			db = DriverManager.getConnection(dbpath, dbuser, dbpasswd);
			
			System.out.println("Created database connection : " + dbpath + " user : " + dbuser);
		} catch (ClassNotFoundException ex) {
			System.out.println("Class not found : " + ex);
		} catch (SQLException ex) {
			System.out.println("Database connection error : " + ex);
		}
	}
	
	public String getHello(String myData) {
		String helloName = "Hello tickets";
		
		String agencyList = makexml(myData);
		ta1.setText(agencyList);
		
		return helloName;
	}

	public List<String> getPcc(String xmldata) {
		String mydata = makexml(xmldata);
		List<String> mypccs = new ArrayList<String>();
		String[] mylist = mydata.split("\n");
		
		String mystr = "";
		for(int i = 0; i < mylist.length; i++) {
			if(mylist[i].trim() != null) {
				String[] mypcc = mylist[i].trim().split("     ");
				if(mypcc.length > 1) {
					mystr = mypcc[mypcc.length - 1].trim().replace(")", "");
					if(mystr == null) mystr = "CODE";
					if(!mystr.equals("CODE")) {
						mypccs.add(mystr);
						addpcc(mystr, mypcc[0].trim());
					}
				}
			}
		}
		
		return mypccs;
	}

	public String makexml(String xmldata) {
		value = "";

        try {
			InputStream in = new ByteArrayInputStream(xmldata.getBytes("UTF-8"));

			DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
			DocumentBuilder builder = factory.newDocumentBuilder();				
   			Document doc = builder.parse(in);

			NodeList el = doc.getElementsByTagName("LINE");
			
			for (int i=0; i < el.getLength(); i++) {
				if(el.item(i).getTextContent()!=null) {
					if(!el.item(i).getTextContent().trim().equals(")"))
						value += el.item(i).getTextContent() + "\n";
				}
			}
			
			ta1.setText(value);
        } catch (Exception ex) {
        	System.out.println("XML Error : " + ex.getMessage());
        }

		return value;
	}

	public String makehmpr(String xmldata) {
		String mydata = "";
		if(process_logs) mydata = xmldata;
		else mydata = makexml(xmldata);

		String[] mylist = mydata.split("\n");
		String ticketList = "";
			
		value = "";
		String ticketpcc = "";
		String bookpcc = "";
		String bpcc = "";
		String bson = "";
		String void_check = "";
		
		if(!process_logs) processsegs();
		if(!process_logs) insLogs(mydata);

		for(int i = 0; i < (mylist.length - 6); i++) {
			if(mylist[i].length() > 0) {
				if((mylist[i].charAt(0) >= '0') && (mylist[i].charAt(0) <= '9')) {					
					String myticket = mylist[i].substring(0, 15).replace(" ", "").replace("-", "").trim();
					String ll = mylist[i].trim();
					if(ll.length() > 16) ticketpcc = ll.substring(ll.length() - 8, ll.length()).trim();
					if(mylist[i + 4].trim().length() > 8) {
						bookpcc = mylist[i + 4].substring(35, 43).trim();
						ticketpcc = mylist[i + 4].substring(43, 48).trim();
						void_check = mylist[i + 1].substring(13, 15).trim();
						if(!void_check.equals("VA")) {
							int j = bookpcc.length();
							if(j > 6) {
								bson = bookpcc.substring(j-3, j).trim();
								bpcc = bookpcc.substring(0, j-3).trim();
							} else if(j > 4) {
								bson = bookpcc.substring(j-2, j);
								bpcc = bookpcc.substring(0, j-2).trim();
							}

							try {
								if((j > 4) && (j < 8)) {
									Long tkt = Long.parseLong(myticket);
									String mt =  "";
									if(!process_logs) mt = addticket(myticket, ticketpcc, bookpcc, bpcc, bson, mylist[i + 1].trim(),  mylist[i + 4].trim(), mylist[i + 6].trim()); 
									ticketList += myticket + ",";
									
									if(process_logs) {
										updateTicket(myticket, ticketpcc, bookpcc, bpcc, bson);
										/*System.out.println("Tickets : " + ll);
										System.out.println(mylist[i + 1] + " : " + mylist[i + 1].substring(13, 15).trim()); 
										System.out.println("Booking : " + ticketpcc + " : " + bookpcc + " : " + mylist[i + 4]);
										System.out.println("SON : " + bson + " : BPCC : " + bpcc);*/
									}
								}
							} catch (NumberFormatException ex) {}
						}
					}
				}
			}
		}
		
		return ticketList;
	}

	public void makete(String xmldata) {
		String mydata = makexml(xmldata);
		String[] mylist = mydata.split("\n");
			
		String mystr = "";
		String mytkt = "";
		if(mylist.length > 1) {
			if(mylist[0].length() > 21) mytkt = mylist[0].substring(5, 20).replace(" ", "").trim();
		}

		int segs = 0;
		for(int i = 0; i < mylist.length; i++) {
			if(mylist[i].trim().length() > 50) {
				if(mylist[i].startsWith("  ") && (!mylist[i].startsWith("       "))) {
					if(!mystr.equals("")) segs++;
					mystr += mylist[i] + "\n";					
				}
			}
		}
		
		try {
			if((mytkt != null) && (mytkt.length() > 5)) {
				Long tkt = Long.parseLong(mytkt);
				updateLines(mytkt, mydata, segs);
			}
		} catch (NumberFormatException ex) {}

		ta1.setText(mystr);
	}

	public void addpcc(String pcc, String agencyname) {
		try {
			System.out.println("PCC Query : " + pcc.trim());
			
			String mysql = "SELECT pcc FROM pccs WHERE (pcc = '" + pcc.trim() + "');";
			Statement st = db.createStatement(ResultSet.TYPE_SCROLL_SENSITIVE, ResultSet.CONCUR_READ_ONLY);
			ResultSet rs = st.executeQuery(mysql);
			if(!rs.next()) {
				mysql = "INSERT INTO pccs (pcc, agencyname) VALUES ('" + pcc.trim().toUpperCase() + "', '";
				mysql += agencyname.trim() + "');";
				Statement stup = db.createStatement();
				stup.executeUpdate(mysql);
				stup.close();
			}
			rs.close();
			st.close();
		} catch (SQLException ex) {
			System.out.println("SQL Error 1 : " + ex);
		}
	}

	public void insLogs(String logs) {
		try {
			String i = "0";
			String mysql = "SELECT nextval('logs_logid_seq'::regclass);";
			Statement st = db.createStatement();
			ResultSet rs = st.executeQuery(mysql);
			if(rs.next()) i = rs.getString(1);
			rs.close();
			st.close();

			// Add the log
			mysql = "INSERT INTO logs (logid, logdate, pcc, currency, processdate) VALUES ('";
			mysql += i + "', '" + mydate + "', '" + agencypcc + "', '" + currency + "', current_date);";
			Statement stup = db.createStatement();
			stup.executeUpdate(mysql);
			stup.close();

			// Add the log details
			mysql = "INSERT INTO logdetails (logid, details) VALUES ('";
			mysql += i + "', '" + logs + "');";
			stup = db.createStatement();
			stup.executeUpdate(mysql);
			stup.close();
		} catch (SQLException ex) {
			System.out.println("SQL Error 2 : " + ex);
		}
	}

	public String addticket(String tkts, String ticketpcc, String bookpcc, String bpcc, String bson, String l1, String l2, String l3) {
		String ticket = "";
		try {
			String mysql = "SELECT ticketid, segs FROM tickets WHERE (ticketid = '" + tkts + "');";
			Statement st = db.createStatement(ResultSet.TYPE_SCROLL_SENSITIVE, ResultSet.CONCUR_READ_ONLY);
			ResultSet rs = st.executeQuery(mysql);
			if(!rs.next()) {
				mysql = "INSERT INTO tickets (ticketid, ticketdate, ticketpcc, bookpcc, bpcc, pcc, son, line1, line2, line3) ";
				mysql += "VALUES ('" + tkts + "', '" + mydate + "', '" + ticketpcc + "', '" + bookpcc + "', '" + bpcc;
				mysql += "', '" + agencypcc + "', '" + bson + "', '" + l1 + "', '" + l2 + "', '" + l3 + "');";
				Statement stup = db.createStatement();
				stup.executeUpdate(mysql);
				stup.close();
			}
			ticket = tkts + "\n";

			rs.close();
			st.close();
		} catch (SQLException ex) {
			System.out.println("SQL Error 3 : " + ex);
		}

		return ticket;
	}

	public void updateTicket(String tkts, String ticketpcc, String bookpcc, String bpcc, String bson) {
		String ticket = "";
		try {
			String mysql = "UPDATE tickets SET ticketpcc = '" + ticketpcc + "', ";
			mysql += "bookpcc = '" + bookpcc + "', ";
			mysql += "bpcc = '" + bpcc + "', ";
			mysql += "son = '" + bson + "' ";
			mysql += "WHERE (ticketid = '" + tkts + "');";
			Statement stup = db.createStatement();
	System.out.println(mysql);
			stup.executeUpdate(mysql);
			stup.close();
		} catch (SQLException ex) {
			System.out.println("SQL Error 4 : " + ex);
		}
	}

	public void updateLines(String tkts, String lines, int segs) {
		System.out.println(tkts);

		try {
			String mysql = "SELECT ticketid, details FROM tes WHERE (ticketid = '" + tkts + "');";
			Statement st = db.createStatement(ResultSet.TYPE_SCROLL_SENSITIVE, ResultSet.CONCUR_READ_ONLY);
			ResultSet rs = st.executeQuery(mysql);
			if(!rs.next()) {
				mysql = "INSERT INTO tes(ticketid, details) VALUES ('" + tkts + "', '" + lines + "');";
				Statement stUP = db.createStatement();
				stUP.executeUpdate(mysql);
				stUP.close();
			}
		} catch (SQLException ex) {
			System.out.println("SQL Error 5 : " + ex);
		}
	}

	public void processsegs() {
		try {
			String[] stat = {"VOID", "OPEN", "USED", "EXCH", "RFND", "ARPT", "CKIN", "LFTD", "UNVL", "PRTD", "SUSP"};
			Map<String, Integer> status = new HashMap<String, Integer>();
			for(int i = 0; i < stat.length; i++) status.put(stat[i], 0);

			String mysql = "SELECT ticketid, TVOID, TOPEN, TUSED, TEXCH, TRFND, TARPT, TCKIN, TLFTD, TUNVL, TPRTD, TSUSP, processed";
			mysql += " FROM tickets WHERE processed = false";

			Statement st = db.createStatement(ResultSet.TYPE_SCROLL_SENSITIVE, ResultSet.CONCUR_UPDATABLE);
			ResultSet rs = st.executeQuery(mysql);
			while (rs.next()) {
				//System.out.println(rs.getString("ticketid"));
				mysql = "SELECT ticketid, details FROM tes WHERE ticketid = '" + rs.getString("ticketid") + "';";  
				Statement tst = db.createStatement(ResultSet.TYPE_SCROLL_SENSITIVE, ResultSet.CONCUR_UPDATABLE);
				ResultSet trs = tst.executeQuery(mysql);
				String line4 = null;
				if(trs.next()) line4 = trs.getString("details");
				trs.close();
				tst.close();

				Map<String, Integer> tstatus = new HashMap<String, Integer>();
				for(int i = 0; i < stat.length; i++) tstatus.put(stat[i], 0);
				
				if(line4 != null) {
					String[] mylist = line4.split("\n");
					boolean s = false;
					for(int i = 0; i < mylist.length; i++) {
						if(mylist[i].length() > 0) {
							if(mylist[i].startsWith("   ") && (mylist[i].trim().length() > 50) && (!mylist[i].startsWith("     "))) {
								if(s) {
									String str = mylist[i];
									str = str.trim().substring(0, 4);
									Integer x = status.get(str);
									Integer y = tstatus.get(str);
									if(x == null) {
										System.out.println(str + " : " + mylist[i]);
									} else {
										x++;
										y++;
										status.put(str, x);
										tstatus.put(str, y);
									}
								}
								s = true;
							}
						}
					}

					for(int i = 0; i < stat.length; i++) rs.updateInt("T" + stat[i], tstatus.get(stat[i]).intValue());
					rs.updateBoolean("processed", true);
					rs.updateRow();
				}
			}

			//for(int i = 0; i < stat.length; i++) System.out.println(stat[i] + " = " + status.get(stat[i]).toString());
		
			rs.close();
			st.close();
		} catch (SQLException ex) {
			System.out.println("Database connection error 6 : " + ex);
		}
	}

	public void processtickets() {
		try {
			String mysql = "SELECT ticketid, ticketdate, ticketpcc, bookpcc, pcc, line1, line2, line3, segs ";
			mysql += "FROM tickets ";
			mysql += "WHERE (length(bookpcc) < 3) AND (tvoid = 0) AND (length(line2) > 7);";

			Statement st = db.createStatement(ResultSet.TYPE_SCROLL_SENSITIVE, ResultSet.CONCUR_UPDATABLE);
			ResultSet rs = st.executeQuery(mysql);
			while(rs.next()) {
				String tkt = rs.getString("ticketid");
				tkt = tkt.replace(tkt.substring(0, 3),  tkt.substring(0, 3) + " ");
				String line2 = rs.getString("line2").trim();
				System.out.println(tkt + " : " + line2);
			}

			rs.close();
			st.close();
		} catch (SQLException ex) {
			System.out.println("Database connection error 7 : " + ex);
		}
	}

	public void updatelogs(String sdate, String edate) {
		process_logs = true;

		String mysql = "SELECT logs.logid, logs.logdate, logs.pcc, logdetails.details ";
		mysql += "FROM logs INNER JOIN logdetails ON logs.logid = logdetails.logid ";
		mysql += "WHERE (logs.logdate >= '" + sdate + "') ";
		mysql += "AND (logs.logdate <= '" + edate + "') ";
		mysql += "ORDER BY logs.logid desc;";		
		try {
			Statement tst = db.createStatement(ResultSet.TYPE_SCROLL_SENSITIVE, ResultSet.CONCUR_UPDATABLE);
			ResultSet trs = tst.executeQuery(mysql);
			while(trs.next()) {
				String str = trs.getString("details");
				
				makehmpr(str);
			}
			trs.close();
			tst.close();
		} catch (SQLException ex) {
			System.out.println("Database connection error 8 : " + ex);
		}

		process_logs = false;
	}

	public void closedb() {
		try {
			db.close();
		} catch (SQLException ex) {
			System.out.println("Database connection error 9 : " + ex);
		}
	}

	public void destroy() {
		closedb();	
	}
}

