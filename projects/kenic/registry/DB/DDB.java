package dewcis.DB;

import java.sql.*;

public class DDB {
	
	Connection db = null;

	public void openDatabase() {
		try {
			Class.forName("org.postgresql.Driver");  
			db = DriverManager.getConnection("jdbc:postgresql://localhost/epp", "root", "invent");
		} catch (ClassNotFoundException ex) {
			System.out.println("Cannot find the database driver classes. : " + ex);
		} catch (SQLException ex) {
			System.out.println("SQL Error : " + ex);
		}
	}

	public Connection getDatabase() {
		return db;
	}

	public String callFunction(String function) {
		String result = null;

		try {
			Statement st = db.createStatement();
			ResultSet rs = st.executeQuery(function);
	
			if(rs.next()) result = rs.getString(1);
		} catch (SQLException ex) {
			System.err.println("Database transaction get data error : " + ex);
		}

		return result;
	}

	public void closeDatabase() {
		try {
			db.close();
		} catch (SQLException ex) {
			System.out.println("SQL Error : " + ex);
		}
	}
}
