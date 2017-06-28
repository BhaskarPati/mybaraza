/**
 * @author      Dennis W. Gichangi <dennis.dichangi@dewcis.com>
 * @version     2011.03.29
 * @since       1.6
 * website		www.dewcis.com
 * The contents of this file are subject to the Dew CIS Solutions License
 * The file should only be shared to Metropol Ltd.
 */
package org.baraza.com;

import java.io.File;
import java.io.FileFilter;
import java.util.Map;
import java.util.HashMap;
import java.util.logging.Logger;
import java.util.Date;
import java.text.SimpleDateFormat;
import java.text.ParseException;
import java.lang.Number;

import org.baraza.DB.BDB;
import org.baraza.DB.BQuery;
import org.baraza.xml.BXML;
import org.baraza.xml.BElement;
import org.baraza.server.mail.BMail;
import org.baraza.utils.BLogHandle;
import org.baraza.utils.Bpdf;
import org.baraza.utils.BFileFilter;
import org.baraza.utils.BNumberFormat;

public class BMetroPol {
	Logger log = Logger.getLogger(BMetroPol.class.getName());
	BElement node;
	BLogHandle logHandle;
	BMetroScore metroScore;
	BDB db = null;
	BDB rdb = null;
	Map<Integer, String> messages;
	String ans = "";
	String myScore = "200";

	public BMetroPol(BDB db, BElement node, BLogHandle logHandle) {
		this.node = node;
		this.logHandle = logHandle;
		this.db = db;
		rdb = new BDB(node);
		messages = new HashMap<Integer, String>();
		metroScore = new BMetroScore(logHandle);
		logHandle.config(log);

		log.info("Metropol Server Service started\n");
	}

	public void process() {
		processSMS();
		processRequests();
		processAlert();
		updateMS();
	}

	public void processSMS() {
		String mysql = "SELECT sms_id, sms_number, sms_time, folder_id, message ";
		mysql += "FROM sms ";
		mysql += "WHERE (folder_id = '4')";
		log.fine(mysql);

		BQuery rs = new BQuery(db, mysql);
		while(rs.moveNext()) {
			String msg = rs.getString("message");
			String phoneNumber = rs.getString("sms_number");
			if(msg == null) msg = "";
			msg = msg.toUpperCase();
			String msgp[] = msg.split("#");
			String firstItem = msgp[0].replace("METRO", "").trim();
			System.out.println("Metropol Query Item : " + firstItem);

			mysql = "SELECT entitys.entity_id ";
			mysql += "FROM entitys INNER JOIN entity_phones ON entitys.entity_id = entity_phones.entity_id ";
			mysql += "WHERE (entity_phones.phone_number = '" + phoneNumber + "')";
			mysql += " AND (entitys.verified = true) AND (entitys.is_active = true)";
			String clientID = db.executeFunction(mysql);

			mysql = "SELECT messages.message_id, messages.message_code, messages.message_data ";
			mysql += "FROM messages INNER JOIN entitys ON messages.language_id = entitys.language_id ";
			mysql += "WHERE entitys.entity_id = " + clientID + " ";
			mysql += "ORDER BY messages.message_code";
			BQuery mrs = new BQuery(db, mysql);
			while(mrs.moveNext()) messages.put(mrs.getInt("message_code"), mrs.getString("message_data"));
			mrs.close();
	
			if(firstItem.equals("REG")) {
				registerClient(msgp, phoneNumber);
			} else {
				if(clientID == null) {
					checkClient(phoneNumber);
				} else {
					if(firstItem.equals("EMAIL")) {
						addClientEmail(msgp, clientID, phoneNumber);
					} else if(firstItem.equals("ADDRESS")) {
						addClientAddress(msgp, clientID, phoneNumber);
					} else if(firstItem.equals("PHONE")) {
						addClientPhone(msgp, clientID, phoneNumber);
					} else if(firstItem.equals("BALANCE")) {
						checkBalance(msgp, clientID, phoneNumber);
					} else if(firstItem.equals("PIN")) {
						changePassword(msgp, clientID, phoneNumber);
					} else if(firstItem.equals("CREDIT")) {
						setRequest(clientID, phoneNumber, rs.getString("sms_id"), msg, "3");
					} else if(firstItem.equals("SCORE")) {
						setRequest(clientID, phoneNumber, rs.getString("sms_id"), msg, "4");
					} else if(firstItem.equals("SCORE REPORT")) {
						setRequest(clientID, phoneNumber, rs.getString("sms_id"), msg, "5");
					} else if(firstItem.equals("SCOREREPORT")) {
						setRequest(clientID, phoneNumber, rs.getString("sms_id"), msg, "5");
					} else if(firstItem.equals("ALERT")) {
						setRequest(clientID, phoneNumber, rs.getString("sms_id"), msg, "6");
					} else if(firstItem.equals("BORROW")) {
						setRequest(clientID, phoneNumber, rs.getString("sms_id"), msg, "7");
					} else if(firstItem.equals("CHECK")) {
						setRequest(clientID, phoneNumber, rs.getString("sms_id"), msg, "8");
					} else {
						setRequest(clientID, phoneNumber, rs.getString("sms_id"), msg, "2");

						// Add answer
						ans = "To check your score SMS: METRO SCORE; to get report SMS: METRO SCORE REPORT";
						mysql = "INSERT INTO sms (folder_id, sms_number, message_ready, message) VALUES (";
						mysql += "0, '" + phoneNumber + "', true, '" + ans + "');";
						db.executeQuery(mysql);
					}
				}
			}

			// Close the Query
			rs.recEdit();
			rs.updateField("folder_id", "3");
			rs.recSave();
		}
		rs.close();
	}

	public void checkClient(String phoneNumber) {
		String mysql = "SELECT entitys.entity_id, entitys.id_number, entitys.verified, entitys.is_active, ";
		mysql += "entity_phones.entity_phone_id, entity_phones.phone_number ";
		mysql += "FROM entitys INNER JOIN entity_phones ON entitys.entity_id = entity_phones.entity_id ";
		mysql += "WHERE entity_phones.phone_number = '" + phoneNumber + "'";
		BQuery rs = new BQuery(db, mysql);
		if(rs.moveNext()) {
			if(!rs.getBoolean("verified")) {
				ans = "You are already registred but the account is currenly awaiting verification.";
			} else if(!rs.getBoolean("is_active")) {
				ans = "You are already registred but the account is currenly blocked.";
			} else {
				ans = "You are already registred and can query score from this Phone";
			}
		} else {
			ans = "You are not registred, kindly register by sending an SMS: METRO REG#IDNO#FULLNAME#PIN";
		}
		rs.close();

		// Add answer
		mysql = "INSERT INTO sms (folder_id, sms_number, message_ready, message) VALUES (";
		mysql += "0, '" + phoneNumber + "', true, '" + ans + "');";
		db.executeQuery(mysql);
	}		

	public int checkClient(String idNumber, String phoneNumber) {
		int valid = -1;
		String mysql = "SELECT entitys.entity_id, entitys.id_number, entitys.verified, entitys.is_active, ";
		mysql += "entity_phones.entity_phone_id, entity_phones.phone_number ";
		mysql += "FROM entitys INNER JOIN entity_phones ON entitys.entity_id = entity_phones.entity_id ";
		mysql += "WHERE entitys.id_number = '" + idNumber + "'";
		BQuery rs = new BQuery(db, mysql);
		if(rs.moveNext()) {
			if(phoneNumber.equals(rs.getString("phone_number"))) {
				if(!rs.getBoolean("verified")) {
					ans = "You are already registred but the account is currenly awaiting verification.";
					valid = 1;
				} else if(!rs.getBoolean("is_active")) {
					ans = "You are already registred but the account is currenly blocked.";
					valid = 2;
				} else {
					ans = "You are already registred and can query score from this Phone";
					valid = 0;
				}
			} else {
				ans = "You are already registred and can query score from your registred phone and not this one.";
				valid = 3;
			}
		} else {
			mysql = "SELECT phone_number FROM entity_phones WHERE phone_number = '" + phoneNumber + "'";
			String dbPhone = db.executeFunction(mysql);
			if(dbPhone == null) {
				ans = "You are not registred, kindly register by sending an SMS: METRO REG#ID NO#FULLNAME#PIN";
				valid = 4;
			} else {
				ans = "The phone number is already registred in the system with another ID.";
				valid = 5;
			}
		}
		rs.close();

		return valid;
	}

	public void registerClient(String msgp[], String phoneNumber) {
		String mysql = "";
		int valid = -1;
		if(msgp.length>1) valid = checkClient(msgp[1], phoneNumber);
		else ans = "To check on registration status Send an SMS : METRO REG#ID NUMBER";

		if(msgp.length!=4) {
			if(valid == -1) ans = "Kindly send correct registration SMS: METRO REG#IDNO#FULLNAME#PIN";
		} else if(valid == 4) {
			mysql = "INSERT INTO entitys (org_id, entity_type_id, auth_level_id, user_name, ";
			mysql += "ID_Number, entity_name, entity_password, first_password, language_id) ";
			mysql += "VALUES (0, 2, 1, '" + msgp[1].trim() + "', '" +  msgp[1].trim() + "', '" +  msgp[2].trim();
			mysql += "', md5('" +  msgp[3].trim() + "'), '" +  msgp[3].trim() + "', 1)";
			db.executeQuery(mysql);

			mysql = "SELECT max(entity_id) as new_number FROM entitys;";
			String newNumber = db.executeFunction(mysql);
			
			mysql = "INSERT INTO entity_phones (entity_id, phone_number, ID_Number) ";
			mysql += "VALUES (" + newNumber + ", '" + phoneNumber + "', '" + msgp[1].trim() + "')";
			db.executeQuery(mysql);

			ans = "Welcome to Metropol Credit Bureau Services.Your registration details are being verified.We shall notify you once the registration process is completed.";
		}

		// Add answer
		mysql = "INSERT INTO sms (folder_id, sms_number, message_ready, message) VALUES (";
		mysql += "0, '" + phoneNumber + "', true, '" + ans + "');";
		db.executeQuery(mysql);
	}

	public void addClientEmail(String msgp[], String clientID, String phoneNumber) {
		String mysql = "";
		if(msgp.length==2) {
			String email = msgp[1].trim();
			if((email.indexOf("@")>1) && (email.indexOf(".")>1)) {
				mysql = "UPDATE entitys SET email = '" + msgp[1] + "' WHERE (entity_id = '" + clientID + "')";
				db.executeQuery(mysql);
				rdb.executeQuery(mysql);

				ans = "Your email has been updated on the system.";
			} else {
				ans = "Your email address is not correct, re-send correct email address.";
			}
		} else {
			ans = "To update your email send SMS: METRO EMAIL#email";
		}

		// Add answer
		mysql = "INSERT INTO sms (folder_id, sms_number, message_ready, message) VALUES (";
		mysql += "0, '" + phoneNumber + "', true, '" + ans + "');";
		db.executeQuery(mysql);
	}

	public void addClientAddress(String msgp[], String clientID, String phoneNumber) {
		String mysql = "";
		if(msgp.length==5) {
			String address = "P.O. Box " + msgp[1] + "\n" + msgp[3] + " - " + msgp[2] + "\n" + msgp[4];
			mysql = "UPDATE entitys SET address = '" + address + "' WHERE (entity_id = '" + clientID + "')";
			db.executeQuery(mysql);
			rdb.executeQuery(mysql);

			ans = "Your address has been updated on the system.";
		} else {
			ans = "To update your address send SMS: METRO ADDRESS#PO BOX#ZIP Code#Town#Country";
		}

		// Add answer
		mysql = "INSERT INTO sms (folder_id, sms_number, message_ready, message) VALUES (";
		mysql += "0, '" + phoneNumber + "', true, '" + ans + "');";
		db.executeQuery(mysql);
	}

	public void addClientPhone(String msgp[], String clientID, String phoneNumber) {
		String mysql = "";
		if(msgp.length==2) {
			String newPhoneNo = msgp[1].replace(" ", "").trim();
			if(newPhoneNo.startsWith("+")) newPhoneNo = newPhoneNo.substring(1, newPhoneNo.length());
			else if(newPhoneNo.startsWith("0")) newPhoneNo = "254" + newPhoneNo.substring(1, newPhoneNo.length());

			BNumberFormat nf = new BNumberFormat();
			nf.getNumber(newPhoneNo);

			if((nf.getError()==0) && (newPhoneNo.length()==12)) {
				newPhoneNo = "+" + newPhoneNo;
				mysql = "SELECT phone_number FROM entity_phones WHERE phone_number = '" + newPhoneNo + "'";
				String dbPhone = db.executeFunction(mysql);
				if(dbPhone == null) {
					mysql = "INSERT INTO entity_phones (entity_id, phone_number) ";
					mysql += "VALUES (" + clientID + ", '" + newPhoneNo + "')";
					db.executeQuery(mysql);

					ans = "Your phone details has been updated on the system.";
				} else {
					ans = "The phone number is already added on the system";
				}
			} else {
				ans = "The phone number is invalid SMS: METRO PHONE#New Phone Number eg METRO PHONE#0711223344";
			}
		} else {
			ans = "To update your phone details send SMS: METRO PHONE#New Phone Number";
		}

		// Add answer
		mysql = "INSERT INTO sms (folder_id, sms_number, message_ready, message) VALUES (";
		mysql += "0, '" + phoneNumber + "', true, '" + ans + "');";
		db.executeQuery(mysql);
	}

	public void setRequest(String clientID, String phoneNumber, String smsID, String msg, String reqid) {
		// Email inclusion
		boolean canGet = true;

		String mysql = "SELECT request_charge, responce_number ";
		mysql += "FROM request_types WHERE request_type_id = " + reqid;
		BQuery rs = new BQuery(db, mysql);
		String qcharge = null;
		if(rs.moveNext()) qcharge = rs.getString("request_charge");
		String alertType = "0";
		String alertValue = "";

		if(reqid.equals("3")) {
			String msgp[] = msg.split("#");
			if(msgp.length != 3) {
				canGet = false;
				ans = "For proper credit enquery send an SMS : METRO CREDIT#item#amount";
			}
		}

		if(reqid.equals("5")) {
			mysql = "SELECT email FROM entitys WHERE entity_id = " + clientID;
			String myEmail = db.executeFunction(mysql);
			if(myEmail == null) {
				canGet = false;
				ans = "Kindly update your email first by sending an SMS : METRO EMAIL#email address";
			}
		}

		if(reqid.equals("6")) {
			String msgp[] = msg.split("#");
			if(msgp.length != 2) {
				ans = "Send SMS : metro alert query | metro alert score | metro alert LIMIT | metro alert query info";
				canGet = false;
			} else {
				String aType = msgp[1].trim().toUpperCase();
				if(aType.equals("QUERY")) {
					alertType = "1";
					ans = "Your Metro Alert Query is now setup";
				} else if(aType.equals("SCORE")) {
					alertType = "2";
					ans = "Your Metro Alert Score is now setup";
				} else if(aType.equals("INFO")) {
					alertType = "4";
					ans = "Your Metro Alert Info is now setup";
				} else {
					BNumberFormat nf = new BNumberFormat();
					nf.getNumber(aType);
					if(nf.getError() != 0) {
						log.info("Number error for Alert Value");
						ans = "Send SMS : metro alert query | metro alert score | metro alert LIMIT | metro alert query info";
						canGet = false;
					} else {
						alertType = "3";
						ans = "Your Metro Alert Score " + aType + " is now setup";
					}
				}
			}
		}

		if(canGet) {
			mysql = "SELECT request_id FROM requests ";
			mysql += "WHERE (sent = false) AND (entity_id = '" + clientID + "') ";
			mysql += "AND (request_type_id = '" + reqid + "');";
			String rid = db.executeFunction(mysql);

			if(rid == null) {
				mysql = "INSERT INTO requests (request_type_id, auth_level_id, entity_id, request_phone, ";
				mysql += "request_charge, request, alert_type, alert_value, responce_number, current_responce) ";
				mysql += " VALUES (" + reqid + ", 0, " + clientID + ", '" + phoneNumber;
				mysql += "', " + qcharge + ", '" + msg + "', '" + alertType + "', '" + alertValue;
				mysql += "', '" + rs.getString("responce_number") + "', '0');";
				db.executeQuery(mysql);

				mysql = "SELECT max(request_id) as new_number FROM requests;";
				String newNumber = db.executeFunction(mysql);

				mysql = "INSERT INTO request_sms (request_id, sms_id) ";
				mysql += "VALUES (" + newNumber + ", " + smsID + ")";
				db.executeQuery(mysql);

				// Add answer
				if(!qcharge.equals("0")) {
					mysql = "SELECT SUM(ledger_amount) as balance ";
					mysql += "FROM ledger WHERE (entity_id = '" + clientID + "')";
					String myqbal = db.executeFunction(mysql);
					if(myqbal == null) myqbal = "0";
					Float mybal = Float.valueOf(myqbal);
					Float mycharge = Float.valueOf(qcharge);

					if(mycharge > mybal) {
						//ans = "Kindly MPESA " + qcharge + " for your request to be processed.";
						ans = "You have insufficient funds in your account.";
						mysql = "INSERT INTO sms (folder_id, sms_number, message_ready, message) VALUES (";
						mysql += "0, '" + phoneNumber + "', true, '" + ans + "');";
						db.executeQuery(mysql);
					}
				} else {
					mysql = "INSERT INTO sms (folder_id, sms_number, message_ready, message) VALUES (";
					mysql += "0, '" + phoneNumber + "', true, '" + ans + "');";
					db.executeQuery(mysql);
				}
			} else {
				mysql = "INSERT INTO sms (folder_id, sms_number, message_ready, message) VALUES (";
				mysql += "0, '" + phoneNumber + "', true, 'Your have a simiral request pending processing.');";
				db.executeQuery(mysql);
			}
		} else {
			mysql = "INSERT INTO sms (folder_id, sms_number, message_ready, message) VALUES (";
			mysql += "0, '" + phoneNumber + "', true, '" + ans + "');";
			db.executeQuery(mysql);
		}
		rs.close();
	}

	public void checkBalance(String msgp[], String clientID, String phoneNumber) {
		String mysql = "SELECT SUM(ledger_amount) as balance ";
		mysql += "FROM ledger WHERE (entity_id = '" + clientID + "')";
		String myqbal = db.executeFunction(mysql);
		if(myqbal == null) myqbal = "0";

		String ans = "Your account balance is : KES " + myqbal;
		mysql = "INSERT INTO sms (folder_id, sms_number, message_ready, message) VALUES (";
		mysql += "0, '" + phoneNumber + "', true, '" + ans + "');";
		db.executeQuery(mysql);
	}

	public void changePassword(String msgp[], String clientID, String phoneNumber) {
		if(msgp.length==3) {
			String mysql = "SELECT entity_password = md5('" + msgp[1] + "') FROM entitys ";
			mysql += "WHERE entity_id = " + clientID;
			String corrPasswd = db.executeFunction(mysql);
			if(corrPasswd.equals("t")) {
				mysql = "UPDATE entitys SET entity_password = md5('" + msgp[2].trim() + "') ";
				mysql += ", first_password = '" + msgp[2].trim() + "' ";
				mysql += "WHERE entity_id = " + clientID;
				db.executeQuery(mysql);
				ans = "The new PIN has been updated.";
			} else {
				ans = "Old PIN incorrect; to update PIN send SMS: METRO PIN#old PIN#new PIN";
			}
		} else {
			ans = "To update PIN send SMS: METRO PIN#old PIN#new PIN";
		}

		String mysql = "INSERT INTO sms (folder_id, sms_number, message_ready, message) VALUES (";
		mysql += "0, '" + phoneNumber + "', true, '" + ans + "');";
		db.executeQuery(mysql);
	}

	public void processRequests() {
		String mysql = "SELECT entitys.entity_id, entitys.id_number, entitys.email, entitys.first_password, ";
		mysql += "requests.request_id, requests.request_phone, requests.wait_state, ";
		mysql += "requests.request_type_id, requests.auth_level_id, requests.approved, requests.ready, ";
		mysql += "requests.request, requests.sent, requests.request_charge, requests.responce, requests.responce_date, ";
		mysql += "requests.alert_type, requests.alert_value, requests.responce_number, requests.current_responce ";
		mysql += "FROM entitys INNER JOIN requests ON entitys.entity_id = requests.entity_id ";
		mysql += "WHERE (requests.sent = false) AND (requests.request_id <> 6)";

		BQuery rs = new BQuery(db, mysql);
		while(rs.moveNext()) {
			mysql = "SELECT SUM(ledger_amount) as balance FROM ledger WHERE (entity_id = '" + rs.getString("entity_id") + "')";
			String myqbal = db.executeFunction(mysql);
			if(myqbal == null) myqbal = "0";
			Float mybal = Float.valueOf(myqbal);
			int requestType = rs.getInt("request_type_id");
			myScore = "0";

			if(mybal >= rs.getFloat("request_charge")) {
				boolean okay = false;
				if(requestType == 2) {
					okay = rs.getBoolean("approved");
					ans = rs.getString("responce");
				} else if(requestType == 3) {
					okay = processCredit(rs.getString("request"));
				} else if((requestType == 4) || (requestType == 5)) {
					okay = proceesScore(requestType, rs.getString("id_number"), rs.getString("email"), rs.getString("first_password"), rs.getString("request_id"), rs.getString("request_phone"), rs.getInt("wait_state"));
				}

				if(okay) {
					// Close the Query
					mysql = "UPDATE requests SET sent = true, responce_date = now(), score = '" + myScore + "' ";
					mysql += ", responce = '" + ans + "' ";
					mysql += "WHERE request_id = " + rs.getString("request_id");
					db.executeQuery(mysql);

					// Add answer
					mysql = "INSERT INTO sms (folder_id, sms_number, message_ready, message) VALUES (";
					mysql += "0, '" + rs.getString("request_phone") + "', true, '" + ans + "');";
					db.executeQuery(mysql);

					mysql = "SELECT max(sms_id) as new_number FROM sms;";
					String newNumber = db.executeFunction(mysql);

					// Add SMS Message tag
					mysql = "INSERT INTO request_sms (request_id, sms_id) ";
					mysql += "VALUES (" + rs.getString("request_id") + ", " + newNumber + ")";
					db.executeQuery(mysql);

					// Update ledger
					mysql = "INSERT INTO ledger (entity_id, request_id, ledger_amount) ";
					mysql += "VALUES(" + rs.getString("entity_id") + "," + rs.getString("request_id") + ",-" + rs.getString("request_charge") + ")";
					db.executeQuery(mysql);
				}
			}
		}
		rs.close();
	}

	public boolean processCredit(String request) {
		boolean okay = true;

		String msgp[] = request.split("#");
		String amount = msgp[2].trim().replace(",", "").replace(" ", "");
		String mysql = "SELECT credit_info.credit_info_responce ";
		mysql += "FROM credit_info ";
		mysql += "WHERE (credit_info.credit_info_query = '" + msgp[1].trim().toLowerCase() + "') ";
		mysql += "AND (credit_info.min_amount < " + amount + ") ";
		mysql += "AND (credit_info.max_amount > " + amount + ")";
		BQuery rs = new BQuery(db, mysql);

		int i = 0;
		ans = "";
		while(rs.moveNext()) {
			if(i < 2) {
				ans += rs.getString("credit_info_responce") + " ";
			}
			i++;
		}
		rs.close();

		if(i==0) ans = "No bank found offering the product."; 
	
		return okay;
	}

	public boolean proceesScore(int requestType, String idNumber, String email, String firstPassword, 
		String requestID, String requestPhone, int waitState) {

		String product = "10101";
		if(requestType == 5) product = "10102";

		boolean okay = true;
		String myScoreTrans = "no Score";
		String mysql = "";
		String myReport = null;

		myScore = metroScore.getScore(idNumber);
		if(requestType == 5) myReport = metroScore.getReport(idNumber);

		if(myScore == null) {
			// send wait message
			if(waitState == 0) {
				ans = "You request has been received, please wait for the Query.";
				mysql = "INSERT INTO sms (folder_id, sms_number, message_ready, message) VALUES (";
				mysql += "0, '" + requestPhone + "', true, '" + ans + "');";
				db.executeQuery(mysql);

				mysql = "UPDATE requests SET wait_state = 1 WHERE request_id = " + requestID;
				db.executeQuery(mysql);
			}
		} else if(myScore.equals("X999")) {
			// send wait message
			if(waitState == 0) {
				ans = "You request has been received, please wait for the Query.";
				mysql = "INSERT INTO sms (folder_id, sms_number, message_ready, message) VALUES (";
				mysql += "0, '" + requestPhone + "', true, '" + ans + "');";
				db.executeQuery(mysql);

				mysql = "UPDATE requests SET wait_state = 1 WHERE request_id = " + requestID;
				db.executeQuery(mysql);
			}
		} else {
			myScoreTrans = "Metro Credit Score is : " + myScore;

			boolean isReport = true;
			if(myScore.equals("X909") || myScore.equals("S909")) { 
				myScore = "250";
				isReport = false;
			}

			// Check on score grade and value
			mysql = "SELECT sms_message ";
			mysql += "FROM points ";
			mysql += "WHERE (Low_Range <= " + myScore + ") AND (High_Range >= " + myScore + ")";
			String smsg = db.executeFunction(mysql);
			ans = "METRO SCORE : " + myScore + " " + smsg;

			// Processess the file
			if((isReport) && (requestType == 5)) {
				String myoDir = "/mnt/filestore/";
				File myDir = new File(myoDir);
				FileFilter filter = new BFileFilter(myReport);
				System.out.println("Report Request : " + myReport);
				File ls[] = myDir.listFiles(filter);
				File myFile = null;
				long filelen = 0;
				for(File lsf : ls) {
					System.out.println(lsf.getName() + " M " + lsf.lastModified());
					if(filelen < lsf.lastModified()) {
						filelen = lsf.lastModified();
						myFile = lsf;
					}
				}

				if(myFile != null) {
					System.out.println("MY FILE : " + myFile.getAbsolutePath());

					String reportName = myFile.getName();
					String nDir = "/opt/crystalball/reports";
					Bpdf pdf = new Bpdf();
					pdf.encryptPdf(myFile.getAbsolutePath(), nDir + reportName, firstPassword);

					BMail mail = new BMail(node, logHandle);
					mail.setAttachFile(nDir, reportName);
					Map<String, String> headers = new HashMap<String, String>();
					Map<String, String> reports = new HashMap<String, String>();
					String mymail = "Hello\n\nFind report attached.";
					okay = mail.sendMail(email, "Metro report", mymail, true, headers, reports);
					ans = "The report has been sent to your email.";
					mail.close();
				}
			}
		}

		return okay;
	}

	public void processAlert() {
		Map<String, Boolean> marketInfo = new HashMap<String, Boolean>();
		String mysql = "SELECT market_info_id, market_info, created_date, public_info ";
		mysql += "FROM market_info ";
		mysql += "WHERE (message_ready = true) AND (message_sent = false)";
		BQuery mrs = new BQuery(db, mysql);

		mysql = "SELECT entitys.entity_id, entitys.id_number, entitys.email, ";
		mysql += "requests.request_id, requests.request_phone, ";
		mysql += "requests.request_type_id, requests.auth_level_id, requests.approved, requests.ready, ";
		mysql += "requests.request, requests.sent, requests.request_charge, requests.responce, requests.responce_date, ";
		mysql += "requests.alert_type, requests.alert_value, requests.responce_number, requests.current_responce, ";
		mysql += "requests.last_responce, requests.score, ";
		mysql += "ledger.ledger_id, ledger.ledger_amount ";
		mysql += "FROM (entitys INNER JOIN requests ON entitys.entity_id = requests.entity_id) ";
		mysql += "LEFT JOIN ledger ON requests.request_id = ledger.request_id ";
		mysql += "WHERE (request_type_id = 6) ";
		mysql += "AND (requests.last_responce < now()) AND (requests.responce_number > requests.current_responce)";
		BQuery rs = new BQuery(db, mysql);
		while(rs.moveNext()) {
			String idNumber = rs.getString("id_number");
			int alertType = rs.getInt("alert_type");
			String requestID = rs.getString("request_id");
			String requestPhone = rs.getString("request_phone");

			// Charge the client
			if(rs.getString("ledger_id") == null) {
				mysql = "SELECT SUM(ledger_amount) as balance FROM ledger WHERE (entity_id = '" + rs.getString("entity_id") + "')";
				String myqbal = db.executeFunction(mysql);
				if(myqbal == null) myqbal = "0";
				Float mybal = Float.valueOf(myqbal);

				// Update ledger
				if(mybal >= rs.getFloat("request_charge")) {
					mysql = "INSERT INTO ledger (entity_id, request_id, ledger_amount) ";
					mysql += "VALUES(" + rs.getString("entity_id") + "," + rs.getString("request_id") + ",-" + rs.getString("request_charge") + ")";
					db.executeQuery(mysql);
				}
			}

			if(alertType == 1) {
				BElement qnode = node.getElementByName("QUERY");
				if(qnode != null) {
					BDB qdb = new BDB(qnode);
					if(qdb == null) {
						log.severe("Could not connect to the Activity Query database.");
					} else {
						System.out.println("CONNECTED TO QUERY DB");
						mysql = "SELECT CompanyName, ReasonName FROM personal_enquiries_store ";
						mysql += "WHERE (CustomerID = '" + idNumber + "') ";
						mysql += "AND (TransactionDate > DATEADD(day, -1, current_timestamp))";
						BQuery qrs = new BQuery(qdb, mysql);
						while(qrs.moveNext()) {
							ans = "Your data has queried by " + qrs.getString("CompanyName");
							updateAlert(requestID, requestPhone, null);
						}
						qrs.close();
						qdb.close();
					}
				}
			} else if(alertType == 2) {
				String mScore = metroScore.getScore(idNumber);
				if(myScore != null) {
					if(myScore.equals("X909")) myScore = "250";
					if(myScore.equals("S909")) myScore = "250";
					if(!myScore.equals(rs.getString("score"))) {
						ans = "This is to alert you on change of your Metro Score to " + myScore;
						updateAlert(rs.getString("request_id"), rs.getString("request_phone"), null);
					}
				}
			} else if(alertType == 3) {
				String mScore = metroScore.getScore(idNumber);
				if(myScore != null) {
					if(myScore.equals("X909")) myScore = "250";
					if(myScore.equals("S909")) myScore = "250";
					BNumberFormat nf = new BNumberFormat();
					Number scoreNum = nf.getNumber(myScore);
					Number aValue = nf.getNumber(rs.getString("alert_value"));
					if((scoreNum.intValue() < aValue.intValue()) && (myScore != null) && !myScore.equals("X999")) {
						ans = "This is to alert you on change of your Metro Score to " + myScore;
						ans += " which is below " + rs.getString("alert_value");
						updateAlert(rs.getString("request_id"), rs.getString("request_phone"), null);
					}
				}
			} else if(alertType == 4) {
				mrs.beforeFirst();
				while(mrs.moveNext()) {
					ans = mrs.getString("market_info");
					myScore = "0";
					updateAlert(rs.getString("request_id"), rs.getString("request_phone"), mrs.getString("market_info_id"));
				}
			}

			mysql = "UPDATE requests SET last_responce = last_responce + interval '1 day'";
			mysql += " WHERE request_id = " + rs.getString("request_id");
			db.executeQuery(mysql);
		}
		rs.close();

		mrs.beforeFirst();
		while(mrs.moveNext()) {
			mysql = "UPDATE market_info SET message_sent = true ";
			mysql += "WHERE (market_info_id = " + mrs.getString("market_info_id") + ") AND (message_sent = false)";
			db.executeQuery(mysql);
		}
		mrs.close();
	}

	public void updateAlert(String requestID, String phoneNumber, String marketInfoID) {
		// Update request
		String mysql = "UPDATE requests SET responce_date = now(), score = '" + myScore + "', ";
		mysql += "current_responce = current_responce + 1, responce = '" + ans + "' ";
		mysql += "WHERE request_id = " + requestID;
		db.executeQuery(mysql);

		// Add answer
		mysql = "INSERT INTO sms (folder_id, sms_number, message_ready, message) VALUES (";
		mysql += "0, '" + phoneNumber + "', true, '" + ans + "');";
		db.executeQuery(mysql);

		mysql = "SELECT max(sms_id) as new_number FROM sms;";
		String newNumber = db.executeFunction(mysql);

		// Add SMS Message tag
		mysql = "INSERT INTO request_sms (request_id, sms_id) ";
		mysql += "VALUES (" + requestID + ", " + newNumber + ")";
		db.executeQuery(mysql);

		if(marketInfoID != null) {
			// Add Responce Market info
			mysql = "INSERT INTO request_info (market_info_id, request_id, message) VALUES (";
			mysql +=  marketInfoID + "," + requestID + ", '" + ans + "');";
			db.executeQuery(mysql);
		}
	}

	public void updateMS() {
		String mysql = "SELECT entity_id, entity_name, ID_Number, KRAPIN, is_picked ";
		mysql += "FROM entitys ";
		mysql += "WHERE (verified = true) AND (is_picked = false)";

		BQuery rs = new BQuery(db, mysql);
		while(rs.moveNext()) {
			mysql = "INSERT INTO entitys(entity_id, entity_name, ID_Number, KRAPIN) ";
			mysql += "VALUES ('" + rs.getString("entity_id") + "', '" + rs.getString("entity_name");
			mysql += "', '" + rs.getString("ID_Number") + "', '" + rs.getString("KRAPIN") + "')";
			rdb.executeQuery(mysql);

			// Update the item as picked
			rs.recEdit();
			rs.updateField("is_picked", "true");
			rs.recSave();
		}
		rs.close();

		mysql = "SELECT entitys.entity_id, entity_phones.entity_phone_id, entity_phones.phone_number ";
		mysql += "FROM entitys INNER JOIN entity_phones ON entitys.entity_id = entity_phones.entity_id ";
		mysql += "WHERE (entitys.verified = true) AND (entity_phones.is_picked = false)";

		rs = new BQuery(db, mysql);
		while(rs.moveNext()) {
			mysql = "INSERT INTO entity_phones (entity_phone_id, entity_id, phone_number) ";
			mysql += "VALUES ('" + rs.getString("entity_phone_id") + "', '" + rs.getString("entity_id");
			mysql += "', '" + rs.getString("phone_number") + "')";
			rdb.executeQuery(mysql);

			// Update the item as picked
			mysql = "UPDATE entity_phones SET is_picked = true WHERE entity_phone_id = " + rs.getString("entity_phone_id");
			db.executeQuery(mysql);
		}
		rs.close();
	}

	public void close() {
		rdb.close();
	}

}

