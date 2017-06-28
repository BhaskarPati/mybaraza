/**
 * @author      Dennis W. Gichangi <dennis@openbaraza.org>
 * @version     2011.0329
 * @since       1.6
 * website		www.openbaraza.org
 * The contents of this file are subject to the GNU Lesser General Public License
 * Version 3.0 ; you may use this file in compliance with the License.
 */
package org.baraza.com;

import java.util.logging.Logger;
import java.util.List;
import java.util.ArrayList;
import java.util.Calendar;
import java.text.SimpleDateFormat;
import javax.xml.ws.WebServiceRef;

import org.yu.*;

import org.baraza.utils.BLogHandle;
import org.baraza.xml.BXML;
import org.baraza.xml.BElement;
import org.baraza.DB.BDB;
import org.baraza.DB.BQuery;

public class BYUCash {
	@WebServiceRef(wsdlLocation="http://41.215.225.40:80/MerchantWebServicesApp/MerchantWebServices?WSDL")

	Logger log = Logger.getLogger(BYUCash.class.getName());
	BDB db = null;
	BElement root = null;
	int delay;

	String MerchantShortCode = "";
	String Last4DigitsOfId = "";
	String Last4DigitsOfRegNum = "";
	String AppId = "";
	String sqlserver = "";

	public BYUCash(BDB db, BElement root, BLogHandle logHandle) {
		this.root = root;
		this.db = db;
		db.setUser("root", "localhost");
		logHandle.config(log);

		delay = Integer.valueOf(root.getAttribute("processdelay", "1")).intValue()*1000;

		MerchantShortCode = root.getAttribute("shortcode", "");
		Last4DigitsOfId = root.getAttribute("id", "");
		Last4DigitsOfRegNum = root.getAttribute("regnum", "");
		AppId = root.getAttribute("appid", "");

		sqlserver = root.getAttribute("sqlserver", "");
	}   

	public int process() {
		readClients();
		webClient();

		return delay;
	}

	public void readClients() {
		BDB ldb = new BDB(root);
		if(ldb == null) return;

		String mysql = "SELECT Client_No, Asset_No, Client_Name, Owing FROM yuCash_Customers ORDER BY Client_No;";
		BQuery rs =  new BQuery(ldb, mysql);
		while(rs.moveNext()) {
			mysql = "SELECT ins_client('" + rs.getString("Client_No") + "', '";
			mysql += rs.getString("Asset_No") + "', '" + rs.getString("Client_Name") + "', '";
			mysql += rs.getString("Owing") + "');";
			//System.out.println("SQL : " + mysql);
			db.executeQuery(mysql);
		}
		rs.close();

		mysql = "SELECT payment_id, mobtransactionID, user_name, asset_no, entity_name, SenderMobileNumber, payment_date, amount ";
		mysql += "FROM vw_payments ";
		mysql += "WHERE (exported = false)";
		rs =  new BQuery(db, mysql);
		while(rs.moveNext()) {
			mysql = "INSERT INTO yuCash_Cust_Payment (transaction_id, client_id, asset_id, client_name, phone_number, payment_date, amount) VALUES ('";
			mysql += rs.getString("mobtransactionID") + "', '" + rs.getString("user_name") + "', '";
			mysql += rs.getString("asset_no") + "', '" + rs.getString("entity_name") + "', '";
			mysql += rs.getString("SenderMobileNumber") + "', '" + rs.getString("payment_date") + "', '";
			mysql += rs.getString("amount") + "');";
			String tx = ldb.executeQuery(mysql);

			if(tx == null) {
				mysql = "UPDATE payments SET exported = true WHERE payment_id = '" + rs.getString("payment_id") + "';\n";
				mysql += "INSERT INTO sms (folder_id, message_ready, sms_number, message) VALUES (0, true, '";
				mysql += rs.getString("SenderMobileNumber");
				mysql += "', 'Thanks for payment. We have received and credited " + rs.getString("amount") + " in your account');\n";
				db.executeQuery(mysql);
			}
		}
		rs.close();

		ldb.close();
		System.out.println("Server Database Connected.");

		mysql = "SELECT entity_id, obligation, payment_number, sent_message ";
		mysql += "FROM entitys ";
		mysql += "WHERE (payment_number is not null) AND (sent_message = false)";
		rs =  new BQuery(db, mysql);
		while(rs.moveNext()) {
			mysql = "INSERT INTO sms (folder_id, message_ready, sms_number, message) VALUES (0, true, '";
			mysql += rs.getString("payment_number") + "', 'You balance is : " + rs.getString("obligation") + "');";
			db.executeQuery(mysql);

			rs.recEdit();
			rs.updateField("sent_message", "true");
			rs.recSave();
		}
		rs.close();

		mysql = "SELECT sms.sms_id, sms.sms_number, sms.sms_time, sms.message ";
		mysql += "FROM sms ";
		mysql += "WHERE (sms.folder_id = 3) AND (sms.actioned = false) AND (length(sms.message) < 32)";
		rs =  new BQuery(db, mysql);
		String msg = "";
		while(rs.moveNext()) {
			msg = rs.getString("message");
			if(msg == null) msg = "";
			else msg = msg.toUpperCase().trim();
			String msgs[] = msg.split(" ");

			if(msgs.length > 1) {
				if(msg.startsWith("ON")) {
					System.out.println("ON : " + msgs[1]);
					mysql = "UPDATE entitys SET Payment_Number = '" + rs.getString("sms_number") + "'";
					mysql += " WHERE user_name = '" + msgs[1].trim() + "';\n";
					mysql += "UPDATE sms SET actioned = true WHERE sms_id = '" + rs.getString("sms_id") + "';\n";
					mysql += "INSERT INTO sms (folder_id, message_ready, sms_number, message) VALUES (0, true, '";
					mysql += rs.getString("sms_number") + "', 'You number has been registred');\n";
					db.executeQuery(mysql);
				} else if(msg.startsWith("OFF")) {
					System.out.println("OFF : " + msgs[1]);
					mysql = "UPDATE entitys SET Payment_Number = null WHERE user_name = '" + msgs[1].trim() + "';\n";
					mysql += "UPDATE sms SET actioned = true WHERE sms_id = '" + rs.getString("sms_id") + "';\n";
					mysql += "INSERT INTO sms (folder_id, message_ready, sms_number, message) VALUES (0, true, '";
					mysql += rs.getString("sms_number") + "', 'You number has been deregistred');\n";
					db.executeQuery(mysql);
				} else if(msg.startsWith("BAL")) {
					System.out.println("BAL : " + msgs[1]);
					mysql = "SELECT obligation FROM entitys WHERE user_name = '" + msgs[1].trim() + "';";
					String bal = db.executeFunction(mysql);

					mysql = "UPDATE entitys SET Payment_Number = null WHERE user_name = '" + msgs[1].trim() + "';\n";
					mysql += "UPDATE sms SET actioned = true WHERE sms_id = '" + rs.getString("sms_id") + "';\n";
					mysql += "INSERT INTO sms (folder_id, message_ready, sms_number, message) VALUES (0, true, '";
					mysql += rs.getString("sms_number") + "', 'You balance is : " + bal + "');\n";
					db.executeQuery(mysql);
				}
			} else if(msg.startsWith("BAL")) {
				String sms_number = rs.getString("sms_number");
				if(sms_number == null) sms_number = "";
				System.out.println("BAL : " + sms_number);
				mysql = "SELECT obligation FROM entitys WHERE Payment_Number = '" + sms_number.trim() + "';";
				String bal = db.executeFunction(mysql);

				mysql = "UPDATE entitys SET Payment_Number = null WHERE user_name = '" + msgs[1].trim() + "';\n";
				mysql += "UPDATE sms SET actioned = true WHERE sms_id = '" + rs.getString("sms_id") + "';\n";
				mysql += "INSERT INTO sms (folder_id, message_ready, sms_number, message) VALUES (0, true, '";
				mysql += sms_number + "', 'You balance is : " + bal + "');\n";
				db.executeQuery(mysql);
			} else {
				String sms_number = rs.getString("sms_number");
				if(sms_number == null) sms_number = "";
				System.out.println("RECON : " + sms_number);
				mysql = "SELECT transaction_id FROM transactions WHERE (picked = false) AND (SenderMobileNumber = '" + sms_number.trim() + "');";
				String txno = db.executeFunction(mysql);
				mysql = "SELECT entity_id FROM entitys WHERE (User_name = '" + msg + "');";
				String entity_id = db.executeFunction(mysql);
			
				if((txno != null) && (entity_id != null)) {
					mysql = "UPDATE transactions SET Account_Number = '" + msg + "' WHERE transaction_id = '" + txno + "';";
					db.executeQuery(mysql);
				}
				mysql = "UPDATE sms SET actioned = true WHERE sms_id = '" + rs.getString("sms_id") + "';\n";
				db.executeQuery(mysql);
			}
		}
		rs.close();
	}	

	public void webClient() {
        try {
			MerchantWebServices service = new MerchantWebServices();
			System.out.println("Retrieving the port from the following service: " + service);

			Calendar cal = Calendar.getInstance();
			SimpleDateFormat dateParse = new SimpleDateFormat("dd/MM/yyyy HH:mm:ss");
			System.out.println("Running YU Web service : " + dateParse.format(cal.getTime()));

			MerchantWebServicesAppPortType port = service.getMerchantServicesPortHTTP();
			MerchantHistoryInput newmhi = new MerchantHistoryInput();

			newmhi.setToDate(dateParse.format(cal.getTime()));
			cal.add(Calendar.DATE, -1);
			newmhi.setFromDate(dateParse.format(cal.getTime()));

			newmhi.setMerchantShortCode(MerchantShortCode);
			newmhi.setLast4DigitsOfId(Last4DigitsOfId);
			newmhi.setLast4DigitsOfRegNum(Last4DigitsOfRegNum);
			newmhi.setAppId(AppId);

			/* Test configurations 
			newmhi.setMerchantShortCode("100100");
			newmhi.setFromDate("15/08/2010 00:00:00");
			newmhi.setToDate("17/08/2010 23:59:59");
			newmhi.setLast4DigitsOfId("5252");
			newmhi.setLast4DigitsOfRegNum("0201");
			newmhi.setAppId("11111111");*/

System.out.println("BASE 100 : Set Parameters " + dateParse.format(cal.getTime()));
			List<MerchantHistoryOutput> output = new ArrayList<MerchantHistoryOutput>(port.retrieveHistory(newmhi).getMerchantHistoryOutput());

System.out.println("BASE 200 : Get results " + output.size());
			for(MerchantHistoryOutput mho : output) {
				String trxID = mho.getTrasnactionId();
				boolean addData = false;
				if(trxID != null) {
					String mysql = "SELECT mobtransactionID FROM transactions WHERE mobtransactionID = '";
					mysql += trxID + "';";
					if(db.executeFunction(mysql) == null) addData = true;
				}
				if(addData) {
					String mysql = "INSERT INTO transactions (mobtransactionID,ResponseCode,TrDateTimeStamp,SenderMobileNumber,FirstName,LastName,Message,AmountReceived) VALUES (";
					mysql += "'" + mho.getTrasnactionId() + "'" + ", "  + "'" + mho.getResponseCode()  + "'" +  ", "   + "'" +  mho.getDateTimeStamp() + "'" +   ", "  + "'+" +  mho.getSenderMobileNumber()  + "'" +  ", ";
					mysql +=  "'" +  mho.getFirstName() + "'"  + ", " +  "'" + mho.getLastName() + "','" + mho.getMessage() + "','" + mho.getAmountReceived() + "');\n";
					System.out.println(mysql);

					db.executeQuery(mysql);
				}
			}
System.out.println("BASE 300 : Close service execution");
		} catch(Exception e) {
			e.printStackTrace();
		}
	}

	public void close() {
		db.close();
	}
}
