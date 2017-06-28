import java.util.Calendar;
import java.util.Date;
import java.sql.Timestamp;
import java.sql.ResultSet;
import java.sql.Statement;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class BSMSMonitoring {

	public static void main(String[] args) {
		BSMSMonitoring sms_mon = new BSMSMonitoring();
		sms_mon.monitor();
		
	}

	public void monitor() {
		System.out.println("Staring SMS monitoring");
		
		Connection monDB = getConnection("jdbc:postgresql://localhost:5432/hr", "postgres", "Invent2k");
		if(monDB == null) return;
		
		Connection bunsonDB = getConnection("jdbc:postgresql://62.24.116.56:5432/bunson", "root", "invent");
		if(bunsonDB == null) {
			addEMail(monDB, "Cannot connect to Bunsons database");
		} else {
			String smsError = remoteChecks(bunsonDB);
			if(smsError != null) addEMail(monDB, "Bunsons SMS : " + smsError);
			else System.out.println("Bunsons SMS okay");
			
			String emailError = monitorEmails(bunsonDB);
			if(emailError != null) addEMail(monDB, "Bunsons Email : " + emailError);
			else System.out.println("Bunsons Email okay");
			
			String transportError = monitorTransport(bunsonDB);
			if(transportError != null) addEMail(monDB, "Bunsons Transport : " + transportError);
			else System.out.println("Bunsons Transport okay");
		}
		
		Connection faidaplusDB = getConnection("jdbc:postgresql://192.168.0.9:5432/faidaplus", "sms_user", "Invent2k");
		if(faidaplusDB == null) {
			addEMail(monDB, "Cannot connect to faidaPlus database");
		} else {
			String smsError = remoteChecks(faidaplusDB);
			if(smsError != null) addEMail(monDB, "faidaPlus SMS : " + smsError);
			else System.out.println("faidaPlus SMS okay");
		}
		
		Connection smsDB = getConnection("jdbc:postgresql://192.168.0.9:5432/sms", "postgres", "Invent2k");
		if(smsDB == null) {
			addEMail(monDB, "Cannot connect to SMS database");
		} else {
			String smsError = execute(smsDB);
			if(smsError != null) addEMail(monDB, smsError);
			else System.out.println("SMS system okay");
		}
		
		closeDB(monDB);
		closeDB(bunsonDB);
		closeDB(faidaplusDB);
		closeDB(smsDB);
	}
	
	public String execute(Connection smsDB) {
		String smsError = null;
		try {
			String sql = "SELECT sms_id, folder_id, sms_origin, sms_number, sms_time ";
			sql += "FROM sms ";
			sql += "WHERE sms_id = ";
			sql += "(SELECT max(sms_id) FROM sms WHERE (folder_id = 0) AND (message_ready = true) AND (sent = false) AND (number_error = false));";
			Statement st1 = smsDB.createStatement();
			ResultSet rs1 = st1.executeQuery(sql);
			
			sql = "SELECT last_sent, send_error, error_email, email_time, narrative ";
			sql += "FROM sms_configs WHERE sms_config_id = 0;";
			Statement st2 = smsDB.createStatement();
			ResultSet rs2 = st2.executeQuery(sql);
			
			if(rs2.next()) {
				boolean sendError = rs2.getBoolean("send_error");
				if(sendError) smsError = "SMS sending error : " + rs2.getString("narrative");
			
				if(rs1.next()) {
					Timestamp smsTime = rs1.getTimestamp("sms_time");
					Date currentTime = new Date();
					Long difference = (currentTime.getTime() - smsTime.getTime()) / (1000 * 60);

					System.out.println("SMS Error : " + difference);
					if(difference > 70) smsError = "SMS have not been sent for : " + difference.toString();
				}
			}
			
			sql = "SELECT COALESCE(sum(sms_units - sms_count), 0) as sms_bal ";
			sql += "FROM vw_load_usage;";
			Statement st3 = smsDB.createStatement();
			ResultSet rs3 = st3.executeQuery(sql);
			if(rs3.next()) {
				int smsBal = rs3.getInt("sms_bal");
				if(smsBal < 3000) smsError = "The SMS credit is about to run out please to up";
			}
			
			rs1.close();
			st1.close();
			rs2.close();
			st2.close();
			rs3.close();
			st3.close();
		} catch(SQLException ex) {
			System.out.println("Error: " + ex);
		}
		
		return smsError;
	}
	
	
	public String monitorEmails(Connection smsDB) {
		String smsError = null;
		
		try {
			String sql = "SELECT min(sys_emailed.created) as last_sent ";
			sql += "FROM sys_emails, sys_emailed, transfers ";
			sql += "WHERE (transfers.transfer_id = sys_emailed.table_id) AND (transfers.email_ready = true) ";
			sql += "AND (sys_emailed.emailed = false) ";
			sql += "AND (sys_emails.sys_email_id = sys_emailed.sys_email_id); ";
			Statement st1 = smsDB.createStatement();
			ResultSet rs1 = st1.executeQuery(sql);
			
			if(rs1.next()) {
				if(rs1.getString("last_sent") != null) {
					Timestamp emailTime = rs1.getTimestamp("last_sent");
					Date currentTime = new Date();
					Long difference = (currentTime.getTime() - emailTime.getTime()) / (1000 * 60);

					System.out.println("Email Error : " + difference);
					if(difference > 70) smsError = "Travel Email have not been sent for : " + difference.toString();
				}
			}
				
			rs1.close();
			st1.close();
		} catch(SQLException ex) {
			System.out.println("Error: " + ex);
		}
	
		return smsError;
	}
	
	public String remoteChecks(Connection smsDB) {
		String smsError = null;
		try{
			String sql = "SELECT sms_id, folder_id, sms_origin, sms_number, sms_time ";
			sql += "FROM sms ";
			sql += "WHERE sms_id = ";
			sql += "(SELECT max(sms_id) FROM sms WHERE (folder_id = 0) AND (message_ready = true) AND (sent = false) AND (number_error = false));";
			Statement st1 = smsDB.createStatement();
			ResultSet rs1 = st1.executeQuery(sql);
			
			if(rs1.next()) {
				Timestamp smsTime = rs1.getTimestamp("sms_time");
				Date currentTime = new Date();
				Long difference = (currentTime.getTime() - smsTime.getTime()) / (1000 * 60);

				System.out.println("SMS Error : " + difference);
				if(difference > 70) smsError = "SMS have not been sent for : " + difference.toString();
			}
			
			rs1.close();
			st1.close();
		} catch(SQLException ex){
			System.out.println("Error: " + ex);
		}
		
		return smsError;
	}
	
	
	public String monitorTransport(Connection bunsonDB) {
		String transportError = null;
		
		try {
			String sql = "SELECT etravel_id , picked, created_at::timestamp, CURRENT_TIMESTAMP::timestamp AS now, "
			+ "(EXTRACT('epoch' FROM (CURRENT_TIMESTAMP::timestamp-created_at::timestamp))/60/60) as difference "
			+ "FROM etravel "
			+ "WHERE picked = false "
			+ "AND (EXTRACT('epoch' FROM (CURRENT_TIMESTAMP::timestamp-created_at::timestamp))/60/60) > 2 "
			+ "AND etravel_id = (SELECT MAX(etravel_id) FROM etravel); ";
			Statement st1 = bunsonDB.createStatement();
			ResultSet rs1 = st1.executeQuery(sql);
			
			if(rs1.next()) transportError = "Bunson Transport script needs synchronisation to backend"; 
				
			rs1.close();
			st1.close();
		} catch(SQLException ex) {
			System.out.println("Error: " + ex);
		}
	
		return transportError;
	}
	
	public void addEMail(Connection monDB, String narrative) {
		try {
			System.out.println("Adding Error Email : " + narrative);
			
			String insEmail = "INSERT INTO sys_emailed(org_id, sys_email_id, table_name, email_type, narrative) ";
			insEmail += "VALUES (0, 10, 'SMS error', 10, '" + narrative + "');";        
		
			Statement st = monDB.createStatement();
			st.execute(insEmail);
			st.close();
		} catch (SQLException ex) {
			System.err.println("Database executeQuery error : " + ex);
		}
	}
	
    public Connection getConnection(String dbPath, String dbUser, String dbPassword){
		Connection conn = null;
		
		try {
			Class.forName("org.postgresql.Driver");
			conn = DriverManager.getConnection(dbPath, dbUser, dbPassword);
		} catch (ClassNotFoundException ex) {
			System.err.println("Error Getting Connection : CNF > " + ex.getMessage());
		} catch (SQLException ex) {
			System.err.println("Error Getting Connection SQE > " + ex.getMessage());
		}
	
		return conn;
	}

    public void closeDB(Connection db) {
		try {
			if(db != null) db.close();
		} catch (SQLException ex) {
			System.err.println("Error Getting Connection SQE > " + ex.getMessage());
		}
	}


}
