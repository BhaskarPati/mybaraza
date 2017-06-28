import java.sql.*;

public class clearBFSMS {

	public static void main(String args[]) {
		clearSMS("jdbc:sqlserver://bfeeds.dewcis.com:1433;databaseName=GIDS_BTS;selectMethod=cursor");
		clearSMS("jdbc:sqlserver://bfeeds.dewcis.com:1433;databaseName=GIDS_FCM;selectMethod=cursor");
	}

	public static void clearSMS(String DBPath) {

		try {
			Connection db = DriverManager.getConnection(DBPath, "sa", "Tr@velp0rt2017");

			// SMS Clear
			String mysql = "UPDATE sms SET is_sent = '1' WHERE is_sent = '0';";
			Statement stUpd = db.createStatement();
			stUpd.execute(mysql);
			stUpd.close();

			// Email clear
			mysql = "UPDATE email SET is_picked = 1 WHERE is_picked = 0;";
			stUpd = db.createStatement();
			stUpd.execute(mysql);
			stUpd.close();

System.out.println("BASE Done");
			
			db.close();
		} catch (SQLException ex) {
			System.out.println("Database connection error : " + ex);
		}
	}
}
