import java.sql.*;
import javax.swing.*;
import java.awt.BorderLayout;
import java.awt.GridLayout;

import javax.swing.SpinnerModel;
import javax.swing.SpinnerDateModel;

import java.util.Calendar;
import java.util.Date;
import java.text.DecimalFormat;
import java.text.SimpleDateFormat;

import java.awt.event.ActionListener;
import java.awt.event.ActionEvent;
import java.lang.Math;

import javax.swing.*;
import java.awt.*;
import java.io.*;


public class viewer implements ActionListener {
	public JPanel panel, pcontrol, panel1, panel2, panel3, panel4;
	JTabbedPane tabbedPane;
	JLabel lb1, lb2, lb3, lb4, lb5;
	JTextField tf1, tf2, tf3;
	JSpinner df1, df2;
	JButton bt1, bt2, bt3, bt4;
	JScrollPane spa, spb,spc,spd; 
	JTextArea ta, tb, tc, td;
	Connection db; 
	String filecurrency = "KES";
	String full; 
	int i=0;

	public viewer() {
		
		panel = new JPanel(new BorderLayout());
		pcontrol = new JPanel(new GridLayout(4, 4));
		
		panel.add(pcontrol, BorderLayout.PAGE_START);
		
		Calendar calendar = Calendar.getInstance();
		Date initDate = calendar.getTime();
		calendar.add(Calendar.DAY_OF_MONTH, -20);
		Date secDate = calendar.getTime();
        calendar.add(Calendar.YEAR, -100);
        Date earliestDate = calendar.getTime();
        calendar.add(Calendar.YEAR, 200);
        Date latestDate = calendar.getTime();
        SpinnerModel dm1 = new SpinnerDateModel(secDate, earliestDate, latestDate, Calendar.YEAR);
		df1 = new JSpinner(dm1);
        df1.setEditor(new JSpinner.DateEditor(df1, "dd/MM/yyyy"));
		SpinnerModel dm2 = new SpinnerDateModel(initDate, earliestDate, latestDate, Calendar.YEAR);
		df2 = new JSpinner(dm2);
        df2.setEditor(new JSpinner.DateEditor(df2, "dd/MM/yyyy"));

		String mymonth = Integer.toString(calendar.get(Calendar.MONTH)+1);

		lb1 = new JLabel("Start Date");
		lb2 = new JLabel("End Date");
		lb3 = new JLabel("Period");
		lb4 = new JLabel("Host");
		lb5 = new JLabel("Access");
		tf1 = new JTextField(20);
		tf2 = new JTextField(20);
		tf3 = new JTextField(20);
		tf1.setText(mymonth);
		tf2.setText("jdbc:sqlserver://192.168.0.124:1433;databaseName=TravCom;selectMethod=cursor");
		//tf2.setText("jdbc:sqlserver://192.168.0.131:1433;databaseName=TravCom;selectMethod=cursor");

		bt1 = new JButton("Process KES");
		bt1.addActionListener(this);

		bt2 = new JButton("Process USD");
		bt2.addActionListener(this);

		bt3 = new JButton("save");
		bt3.addActionListener(this);

		bt4 = new JButton("clear");
		bt4.addActionListener(this);

		pcontrol.add(lb4);
		pcontrol.add(tf2);
		pcontrol.add(lb5);
		pcontrol.add(tf3);

		pcontrol.add(lb3);
		pcontrol.add(tf1);
		pcontrol.add(lb1);
		pcontrol.add(df1);

		pcontrol.add(lb2);
		pcontrol.add(df2);

		pcontrol.add(bt1);
		pcontrol.add(bt2);
		pcontrol.add(bt3);
		pcontrol.add(bt4);

		panel1 = new JPanel(new BorderLayout());
		panel2 = new JPanel(new BorderLayout());
		panel3 = new JPanel(new BorderLayout());
		panel4 = new JPanel(new BorderLayout());
	
		ta = new JTextArea();
		spa = new JScrollPane(ta);
		panel1.add(spa, BorderLayout.CENTER);

		tb = new JTextArea();
		spb = new JScrollPane(tb);
		panel2.add(spb, BorderLayout.CENTER);

		tc = new JTextArea();
		spc = new JScrollPane(tc);
		panel3.add(spc, BorderLayout.CENTER);
		
		
		td = new JTextArea();
		spd = new JScrollPane(td);
		panel4.add(spd, BorderLayout.CENTER);

		tabbedPane = new JTabbedPane();
		tabbedPane.addTab("Invoice", panel1);
		tabbedPane.addTab("Commision", panel2);
		tabbedPane.addTab("Credit Card", panel3);
		tabbedPane.addTab("Cash Sale", panel4);
		panel.add(tabbedPane, BorderLayout.CENTER);
	}

	public String ticket(String ag){
		String full = ag;

		if(ag.length()>9)
			full = ag.substring(0, 4) + "-" + ag.substring(4, 7) + "-" + ag.substring(7, 10);		

		return full;
	}


	public void readdata(String currency) {
		filecurrency = currency;

		try {
			String databaseURL = tf2.getText();
			Class.forName("com.microsoft.sqlserver.jdbc.SQLServerDriver");
			db = DriverManager.getConnection(databaseURL, "sa", tf3.getText());
	
			String query = "SELECT Profiles.InterFaceCode, ARInvoices.InvoiceID, ARInvoices.InvoiceDate, ARInvoices.InvoiceNumber "; 
			query += "FROM ARInvoices INNER JOIN Profiles ON ARInvoices.ProfileNumber = Profiles.ProfileNumber ";
			query += "WHERE (ARInvoices.InvoiceDate >= '" + getDate(df1) + "') AND ARInvoices.InvoiceDate <= ('" + getDate(df2) + "') ";
			query += "AND (Profiles.ProfileType = 0) ";
			query += "ORDER BY ARInvoices.InvoiceDate;";
			Statement stmt = db.createStatement();
			ResultSet rs = stmt.executeQuery(query);
			
			String s = "";
			String c = "";
			String creditcard = "";
			String cashSale="";
			String jaba = "";
			while (rs.next()) {
				String sa = "\"Header\",\" \",\" \",\" \",\""; 
				sa += rs.getString("InterFaceCode") + "\"," + tf1.getText();
				sa += ",\"" + FormatDate(rs.getDate("InvoiceDate"));
				sa += "\",\"" + rs.getString("InvoiceNumber") + "\",\"N\",0,\"Credit Sale from TravCom\",";
				sa += "\" \",\" \",\" \",\" \",\" \",\" \",\" \",\" \",0,\" \",\" \",\" \",\" \",1,\"N\",\" \",\" \"\r\n";

				String subsql = "SELECT Profiles.InterFaceCode, SellingFare, CommissionAmount, (SellingFare - CommissionAmount) as CostPrice, ";
				subsql += "ARInvoiceDetails.TransactionCode,";
				subsql += "VendorName, TicketNumber, PassengerName, InvoiceDetailID, ARInvoiceDetails.Grossamount, ARInvoiceDetails.ValidatingCarrier, ";
				subsql += "(ARInvoiceDetails.SellingFare - ARInvoiceDetails.Publishedfare) as markup, ";
				subsql += "(CommissionAmount + (ARInvoiceDetails.SellingFare - ARInvoiceDetails.Publishedfare)) as netCommissionAmount, ";
				subsql += "ARInvoiceDetails.productcode, ARInvoiceDetails.tax3 ";
				subsql += "FROM ARInvoiceDetails INNER JOIN Profiles ON ARInvoiceDetails.VendorNumber = Profiles.ProfileNumber ";
				subsql += "WHERE (TransactionType = 1) AND (ARInvoiceDetails.currencycode = '" + currency + "') ";
				subsql += "AND (InvoiceID = " + rs.getString("InvoiceID") + ");";
				Statement sbst = db.createStatement();
				ResultSet sbrs = sbst.executeQuery(subsql);

				String sb = "";
				String subsale = "";
				while (sbrs.next()) {
					subsql = "SELECT DepartureCityCode, DepartureInfo, ArrivalCityCode ";
					subsql += "FROM segments ";
					subsql += "WHERE (InvoiceDetailID = " + sbrs.getString("InvoiceDetailID") + ");";
					Statement ssbst = db.createStatement();
					ResultSet ssbrs = ssbst.executeQuery(subsql);
					String segment = null;
					while (ssbrs.next()) {
					  if(segment == null) segment = FormatDate(ssbrs.getDate("DepartureInfo")) + " " + ssbrs.getString("DepartureCityCode");
					  segment +=  " " + ssbrs.getString("ArrivalCityCode");
					}
					ssbrs.close();
					ssbst.close();
					sb += "\"Detail\",";
					sb += ftm(sbrs.getDouble("Grossamount")) + ",1,";
					sb += ftm(sbrs.getDouble("Grossamount")) + ",";
					sb += ftm(sbrs.getDouble("Grossamount")) + ",\" \",0,0,0,\"";
					sb += "0100" + sbrs.getString("ValidatingCarrier") + "\",\"";
					if("CC".equals(sbrs.getString("TransactionCode"))) sb += "CCSale:";
					sb += rs.getString("InvoiceNumber") + " T:";
					if(sbrs.getString("TicketNumber") != null) sb += sbrs.getString("TicketNumber");
					sb += "\",\"6\",\"   \",\"   \"\r\n";

					if("CC".equals(sbrs.getString("TransactionCode"))) {
						sb += "\"Detail\",-";
						sb += ftm(0.03 * sbrs.getDouble("Grossamount")) + ",1,-";
						sb += ftm(0.03 * sbrs.getDouble("Grossamount")) + ",-";
						sb += ftm(0.03 * sbrs.getDouble("Grossamount")) + ",\" \",0,0,0,";
						sb += "\"0060094\",\"CCCardCommExp:";
						sb += rs.getString("InvoiceNumber") + " T:";
						if(sbrs.getString("TicketNumber") != null) sb += sbrs.getString("TicketNumber");
						sb += "\",\"6\",\"   \",\"   \"\r\n";
						creditcard +=sa+sb;
						sb="";sa="";
					}

					else{
						sb += "\"Detail\",0,0,0,0,\" \",0,0,0,\"'\",\"";
						if(sbrs.getString("PassengerName") != null) sb += sbrs.getString("PassengerName");
						sb += "\",\"7\",\"\",\"   \"\r\n";	

						if(segment != null) {
						sb += "\"Detail\",0,0,0,0,\" \",0,0,0,\"'\",\"";
						sb += segment;
						sb += "\",\"7\",\"\",\"   \"\r\n";
						}
					}

					String cb = tf1.getText() + ",\"" + FormatDate(rs.getDate("InvoiceDate")) + "\",\"G\",\"" + "0100" + sbrs.getString("ValidatingCarrier") + "\",\"";
					String cb2 = tf1.getText() + ",\"" + FormatDate(rs.getDate("InvoiceDate")) + "\",\"G\",\"" + "0125" + sbrs.getString("ValidatingCarrier") + "\",\"";
					String cb3 = tf1.getText() + ",\"" + FormatDate(rs.getDate("InvoiceDate")) + "\",\"G\",\"";
					if(sbrs.getInt("productcode")==8) cb3 += "0001006" + "\",\"";
					else cb3 += "0001001" + "\",\"";
					String cb4 = tf1.getText() + ",\"" + FormatDate(rs.getDate("InvoiceDate")) + "\",\"G\",\"" + "0125" + sbrs.getString("ValidatingCarrier") + "\",\"";
					String cb5 = tf1.getText() + ",\"" + FormatDate(rs.getDate("InvoiceDate")) + "\",\"G\",\"" + "0950000" + "\",\"";

					subsale += cb;
					cb += rs.getString("InvoiceNumber") + "\",\"" + currency + " Comm. on TKT:";
					cb2 += rs.getString("InvoiceNumber") + "\",\"" + currency + " Comm. on TKT:";
					cb3 += rs.getString("InvoiceNumber") + "\",\"" + currency + " Comm. on TKT:";
					cb4 += rs.getString("InvoiceNumber") + "\",\"" + currency + " VAT on SF:";
					cb5 += rs.getString("InvoiceNumber") + "\",\"" + currency + " VAT on SF:";					

					String cc = ",0,0,\"A\",\"AIR\",\"0000000\",1,1,0,0,0,0";					
					String tiko = ticket(sbrs.getString("TicketNumber"));
					
					cb += "E" + tiko + "\"," + ftm(sbrs.getDouble("netCommissionAmount")) + cc+"\r\n"; 
					cb2 += "E" + tiko + "\"," + ftm(sbrs.getDouble("netCommissionAmount")) + cc+"\r\n"; 
					cb3 += "E" + tiko + "\"," + "-" + ftm(sbrs.getDouble("netCommissionAmount")) + cc+"\r\n";
					cb4 += "E" + tiko + "\"," + ftm(sbrs.getDouble("tax3")) + cc + "\r\n";
					cb5 += "E" + tiko + "\"," + "-" + ftm(sbrs.getDouble("tax3")) + cc + "\r\n";
					subsale += rs.getString("InvoiceNumber") + "\",\"Sale of TKT:";
					subsale += "E"+tiko+ "\"," + "-" + ftm(sbrs.getDouble("Grossamount")) + cc + "\r\n";
		
					c += cb2 + cb3;
					if(sbrs.getInt("tax3") > 0) c += cb4 + cb5;

					//if("CC".equals(sbrs.getString("TransactionCode"))) creditcard +=s;
					
				}

				if("0841500".equals(rs.getString("InterFaceCode"))) {
				    jaba += subsale;
				} else {
				    if(!sb.equals("")) s += sa + sb;
				}
				
				sbrs.close();
				sbst.close();
			}

			ta.setText(s);
			tb.setText(c);
			tc.setText(creditcard);
			td.setText(jaba);
		

		} catch (ClassNotFoundException ex) {
			System.err.println("Cannot find the database driver classes.");
			System.err.println(ex);
		} catch (SQLException ex) {
			System.err.println("Cannot connect to this database.");
			System.err.println(ex);
		}
	}

	public String getDate(JSpinner datafield) {
		SpinnerModel datemodel = datafield.getModel();

		SimpleDateFormat dateformatter = new SimpleDateFormat("yyyy-MM-dd");
        String mydate = dateformatter.format(((SpinnerDateModel)datemodel).getDate());
      
		return mydate;
	}

	public String FormatDate(java.sql.Date data) {

		if(data == null) return "";

		SimpleDateFormat dateformatter = new SimpleDateFormat("dd/MM/yyyy");
        String mydate = dateformatter.format(data);
      
		return mydate;
	}

	public String ftm(double myvalue) {
		DecimalFormat df = new DecimalFormat("######################0.##");
		String mydt = df.format(myvalue);
		return mydt;
	}

	public void actionPerformed(ActionEvent e) {	
		if(e.getActionCommand().equals("Process KES")) readdata("KES");
		else if(e.getActionCommand().equals("Process USD")) readdata("USD");
		else if (e.getActionCommand().equals("save")) saveFile();
		else if (e.getActionCommand().equals("clear")) {
			ta.setText("");
			tb.setText("");
			tc.setText("");
			td.setText("");
		}
    }

	public void saveFile() {
		JFileChooser fc = new JFileChooser();
		fc.setFileSelectionMode(JFileChooser.DIRECTORIES_ONLY);

		SpinnerDateModel datemodel = (SpinnerDateModel)df2.getModel();
		SimpleDateFormat dateformatter = new SimpleDateFormat("_yyyy_MM_dd");
        String mydate = dateformatter.format(datemodel.getDate());

		int result = fc.showSaveDialog(panel);

		if (result == JFileChooser.APPROVE_OPTION) {
			try {
				File sdir = fc.getSelectedFile();
				String invoicefile = sdir.getPath() + System.getProperty("file.separator") + "invoice_" + filecurrency + mydate + ".txt";
				String commfile = sdir.getPath() + System.getProperty("file.separator") + "comm_" + filecurrency + mydate + ".txt";
				String creditfile = sdir.getPath() + System.getProperty("file.separator") + "CreditCard_" + filecurrency + mydate + ".txt";
				String cashFile = sdir.getPath() + System.getProperty("file.separator") + "cashSale_" + filecurrency + mydate + ".txt";
				PrintWriter out = new PrintWriter(new BufferedWriter(new FileWriter(new File(invoicefile))));
				out.print(ta.getText());
				out.close();

				PrintWriter cout = new PrintWriter(new BufferedWriter(new FileWriter(new File(commfile))));
				cout.print(tb.getText());
				cout.close();
				
				PrintWriter dout = new PrintWriter(new BufferedWriter(new FileWriter(new File(creditfile))));
				dout.print(tc.getText());
				dout.close();
				
				PrintWriter eout = new PrintWriter(new BufferedWriter(new FileWriter(new File(cashFile))));
				eout.print(td.getText());
				eout.close();

			} catch (IOException ex) {
				System.out.println("IO Error " +  ex);
			}
		}
	}

}
