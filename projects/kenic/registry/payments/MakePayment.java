package dewcis.payments;

import java.sql.Connection;
import java.sql.Statement;
import java.sql.ResultSet;
import java.sql.SQLException;

import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.text.SimpleDateFormat;
import java.math.BigDecimal;

import java.net.URL;
import java.net.URLConnection;
import java.net.MalformedURLException;
import java.net.URLEncoder;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.io.IOException;

import dewcis.xml.DXML;
import dewcis.xml.DElement;

public class MakePayment {
	String card_name;
	String card_number;
	String card_expiry;
	String card_cvc;
	String trans_domain;
	BigDecimal trans_amount;

	public MakePayment(String name, String number, Date expiry, String cvc, HashMap<String, BigDecimal> amount) {
		card_name = name;
		card_number = number;
		card_cvc = cvc;

		SimpleDateFormat dateparse = new SimpleDateFormat("MMyy");
		card_expiry = dateparse.format(expiry);
		
		for (String i : amount.keySet()) {
			trans_domain = i;
			trans_amount = amount.get(i);
		}
	}

	public String payment(Connection dbc, Integer tid) {
		String url = null;
		String vendorcard = null;
		try {
			String mysql = "SELECT murl, cardnumber FROM sysconfig";
			Statement st = dbc.createStatement();
			ResultSet rs = st.executeQuery(mysql);
			if(rs.next()) {
				url = rs.getString("murl");
				vendorcard = rs.getString("cardnumber");
			}
			rs.close();
			st.close();
		} catch (SQLException ex) {
			System.out.println("SQL Error : " + ex);
		}
		String myresp = "";
		String mydesc = "KENIC domain receipt : " + tid.toString();
		String xmlrequest = "<?xml version=\"1.0\"?>\n<request>\n<code>2</code>\n";
		xmlrequest += "<vendorcard>" + vendorcard + "</vendorcard>\n";
		xmlrequest += "<cardname>" + card_name + "</cardname>\n<cardno>" + card_number + "</cardno>\n";
		xmlrequest += "<cardexpiry>" + card_expiry + "</cardexpiry>\n<pin>" + card_cvc + "</pin>\n";
		xmlrequest += "<desc>" + mydesc + "</desc>\n<amount>" + trans_amount + "</amount>\n</request>";

		try {
			url += "?" + URLEncoder.encode("request", "UTF-8") + "=" + URLEncoder.encode(xmlrequest, "UTF-8");
			URL merchant = new URL(url);
			URLConnection merchantConn = merchant.openConnection();
			merchantConn.connect();

			BufferedReader in = new BufferedReader(new InputStreamReader(merchantConn.getInputStream()));

			String inputLine;
			while ((inputLine = in.readLine()) != null) {
				myresp += inputLine;
				System.out.println(inputLine);
			}
			in.close();
		} catch(MalformedURLException ex) {
			System.out.println("URL Malformed : " + ex);
		} catch(IOException ex) {
			System.out.println("URL Malformed : " + ex);
		}

		return myresp;
	}

	public HashMap<Integer, Integer> updatePayments(Connection dbc, String roid, String ip, String desc) {
		HashMap<Integer, Integer> crtxid = new HashMap<Integer, Integer>();

		Date td = new Date();
		System.out.println("PAYMENT PROCESSING : " + card_number + " from " + ip + " at " + td);
		if(desc == null) desc = "";
		else desc = " : " + desc;

		Integer akey = getSerial(dbc, "credit_transaction_id_seq");
		Integer bkey = 0;
		String myresp = payment(dbc, akey);

		DXML xml = new DXML(myresp, true);
		DElement root = xml.getRoot().getFirst();
		List<DElement> rootlist = root.getElements();

		String success = null;
		String transactionid = null;
		String message = null;
		for(DElement el : rootlist) {
			System.out.println(el.getName());
			List<DElement> ellist = el.getElements();
			String result = el.getName();
			for(DElement ell : ellist) {
				System.out.println(ell.getName() + " : " + ell.getValue());
				if(ell.getName().equals("success")) success = ell.getValue();
				if(ell.getName().equals("transactionid")) transactionid = ell.getValue();
				if(ell.getName().equals("message")) message = ell.getValue();
			}
		}

		if(success == null) success = "";
		String mysql = "";

		if(success.equals("1")) {
			mysql = "INSERT INTO credit_transaction";
			mysql += "(id, client_roid, currency, total, card_type, card_address, card_number, card_expiry, request_ip, ";
			mysql += "status, authorisation, authorised, processor_ref, processor_account_history_id)\n";
			mysql += "VALUES (" + akey.toString() + ", '" + roid + "', 'KES', " + trans_amount.toString() + ", 'KENICPAY', '" + card_name + "', '";
			mysql += card_number + "', '" + card_expiry + "', '" + ip + "', 'completed', '1', now(), '" + transactionid + "', '1');\n";

			bkey = getSerial(dbc, "ledger_id_seq");	
			mysql += "INSERT INTO ledger (id, client_roid, description, currency, total, trans_type, ";
			mysql += "credit_transaction_id, tld, processor_account_history_id)\n";
			mysql += "VALUES (" + bkey.toString() + ", '" + roid + "', 'Receipt" + desc + "', 'KES', -" + trans_amount.toString() + ", 'Payment', ";
			mysql += akey + ",'" + trans_domain + "', 1);\n"; 
			//System.out.println(mysql);
		} else {
			mysql = "INSERT INTO credit_transaction";
			mysql += "(id, client_roid, currency, total, card_type, card_address, card_number, card_expiry, request_ip, ";
			mysql += "status, processor_account_history_id)\n";
			mysql += "VALUES (" + akey.toString() + ", '" + roid + "', 'KES', " + trans_amount.toString() + ", 'KENICPAY', '" + card_name + "', '";
			mysql += card_number + "', '" + card_expiry + "', '" + ip + "', 'declined', '1');\n";
		}

		try {
			Statement stup = dbc.createStatement();
			stup.executeUpdate(mysql);
			crtxid.put(akey, bkey);
			stup.close();
		} catch (SQLException ex) {
			System.out.println("SQL Error : " + ex);
		}

		return crtxid;
	}

	public Integer getSerial(Connection dbc, String serial) {
		Integer sr = null;

		try {
			String mysql = "select nextval('" + serial + "')";
			Statement stsr = dbc.createStatement();
			ResultSet rssr = stsr.executeQuery(mysql);
			if(rssr.next()) sr = rssr.getInt(1);
			rssr.close();
			stsr.close();
		} catch (SQLException ex) {
			System.out.println("SQL Error : " + ex);
		}

		return sr;
	}

}
