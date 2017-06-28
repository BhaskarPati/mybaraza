import java.util.Calendar;
import java.sql.Timestamp;
import java.sql.ResultSet;
import java.sql.Statement;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class BookingFeedMonitor {

	String dbName = "";

	public static void main(String[] args) {
		Calendar calendar = Calendar.getInstance();
		int dayOfWeek = calendar.get(Calendar.DAY_OF_WEEK);
		int hourOfDay = calendar.get(Calendar.HOUR_OF_DAY);
		
		if(args.length != 1) {
			System.out.println("USAGE java -jar bfm.jar <<database name>>");
			return;
		}
                
		if(dayOfWeek >= 2 && dayOfWeek <= 6){
			System.out.println("Working Day  : YES" );
		
			if(hourOfDay >= 8 && hourOfDay <= 18){
				System.out.println("Working Hours  : YES" );
				
				BookingFeedMonitor bf = new BookingFeedMonitor(args[0]);
				bf.run();
			}else{
				System.out.println("Working Hours  : NO" );
			}
		} else {
			System.out.println("Working Day  : NO" );
		}
	}
	
	public BookingFeedMonitor(String dbName) {
		this.dbName = dbName;
	}

    public Connection getConnection(String type){
		Connection conn = null;
		
		try {
			if(type.equals("pg")){
				Class.forName("org.postgresql.Driver");
				conn = DriverManager.getConnection("jdbc:postgresql://localhost:5432/agency","postgres","");
			} else if(type.equals("mssql")) {
				String myUrl = "jdbc:sqlserver://bfeeds.dewcis.com:1433;databaseName=" + dbName + ";selectMethod=cursor";
				Class.forName("com.microsoft.sqlserver.jdbc.SQLServerDriver");
				conn = DriverManager.getConnection(myUrl, "sa", "Tr@velp0rt2017");
			}
		}catch (ClassNotFoundException e) {
			System.err.println("Error Getting Connection : CNF > " + e.getMessage());
		}catch (SQLException ex) {
			System.err.println("Error Getting Connection SQE > " + ex.getMessage());
		}
	
		return conn;
	}
 
	public static long compareTwoTimeStamps(java.sql.Timestamp currentTime, java.sql.Timestamp oldTime){
		long milliseconds1 = oldTime.getTime();
		long milliseconds2 = currentTime.getTime();

		long diff = milliseconds2 - milliseconds1;
		long diffSeconds = diff / 1000;
		long diffMinutes = diff / (60 * 1000);
		long diffHours = diff / (60 * 60 * 1000);
		long diffDays = diff / (24 * 60 * 60 * 1000);

		return diffHours;
	}
	
	
	public void run() {
  
		try{
			Connection pgconn = getConnection("pg"); 
			Connection conn = getConnection("mssql");
			Statement stmt = null;
			
			if(conn == null) {//failed to connect				
				stmt = pgconn.createStatement();
				String sql = "INSERT INTO sys_emailed (sys_email_id, org_id, narrative)";
				sql += " VALUES (2, 0, 'Serve Connection Failed...')";
				stmt.executeUpdate(sql);
				System.out.println("Serve Connection Failed..." );

			} else {//Connected
				System.out.println("Server Connection Successfull..." );
				String query= "SELECT  TravelOrderIdentifier, DatabaseTimeStamp, CURRENT_TIMESTAMP AS today, DATEDIFF(MINUTE, DatabaseTimeStamp, CURRENT_TIMESTAMP) AS difference  FROM TravelOrderEvent WHERE TravelOrderIdentifier = (select max(TravelOrderIdentifier) FROM TravelOrderEvent )";
				Statement st = conn.createStatement();
				ResultSet rs = st.executeQuery(query);
				
				int TravelOrderIdentifier = 0, difference = 0;
				Timestamp DatabaseTimeStamp = null, now = null;

				
				while (rs.next()){
					TravelOrderIdentifier = rs.getInt("TravelOrderIdentifier");
					DatabaseTimeStamp = rs.getTimestamp("DatabaseTimeStamp");
					now = rs.getTimestamp("today");
					difference = rs.getInt("difference");
				}
				
				System.out.format("\nTravelOrderIdentifier : %s, \nDatabaseTimeStamp : %s, \nNow  : %s, \ndifference : %s\n",TravelOrderIdentifier, DatabaseTimeStamp, now,difference );
					
				//get holidays : postress db dates
				String sqlQuery = "SELECT holiday_date from holidays WHERE holiday_date = CURRENT_TIMESTAMP::date"; //where dte = CAST(CURRENT_TIMESTAMP AS DATE)"
				Statement stt = pgconn.createStatement();
				ResultSet res = stt.executeQuery(sqlQuery);
				boolean isHoliday = res.isBeforeFirst();
				if(isHoliday){
					System.out.println("Is Holiday :  YES");
				}else{
					System.out.println("Is Holiday :  No");
					//get difference in timestamp
					long diff = compareTwoTimeStamps(now, DatabaseTimeStamp);
					System.out.println("Time Difference (Hours) :  " + diff);
					
					if(diff >= 1){
						//create email
						System.out.println("Time Difference Ok? : NO \nCreating Email...." );
						stmt = pgconn.createStatement();
						String sql = "INSERT INTO sys_emailed (sys_email_id, org_id, narrative)" + "VALUES (2, 0, 'No Booking dropped in " + diff + " from " + DatabaseTimeStamp +"')";

						int isEmailCreated = stmt.executeUpdate(sql);
						
						if(isEmailCreated > 0){
							System.out.println("Email Created Successfully." );
						}else{
							System.out.println("Email Creating Failed." );
						}
					}else{
						System.out.println("Time Difference Ok? : YES \nExiting...." );
					}
				}
				st.close();
				
				if(conn != null){
					conn.close();
					System.out.println("Closing MSSQL Connection ....");
				}
				if(pgconn != null){
					pgconn.close();
					System.out.println("Closing PGSQL Connection ....");
				}
			}
		}catch (SQLException e){
			System.err.println("Got an error! " + e.toString());
		}
    } 
}
