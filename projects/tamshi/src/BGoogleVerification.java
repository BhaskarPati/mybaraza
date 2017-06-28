import com.google.sitebuilder.SiteBuilderService;
import com.google.sitebuilder.SiteBuilderService.GetVerificationTokenException;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.util.List;
import java.sql.Connection;
import java.sql.Statement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.DriverManager;

/**
 * @author Kevin Marshall
 */
public class BGoogleVerification {
	final String APP_DESCRIPTION = "Site Verification API Java Client Sample";
	final String META_VERIFICATION_METHOD = "DNS";
	final String SITE_TYPE = "INET_DOMAIN";

	public static void main(String args[]) {
		try {
			String driver = "org.postgresql.Driver";
			String dbpath = "jdbc:postgresql://62.24.122.19/tamshi";
			String mysql = "SELECT domain_id, entity_id, zone_id, domain_name, site_name, google_token, google_sync ";
			mysql += "FROM domains WHERE (updated = true) AND (google_sync = false) ";
			mysql += "AND ((now() - created_date) > interval '1 hour')";

			Class.forName(driver);
			Connection db = DriverManager.getConnection(dbpath, "simba", "simba2012SIMBA");
			Statement st = db.createStatement(ResultSet.TYPE_SCROLL_SENSITIVE, ResultSet.CONCUR_UPDATABLE);
			ResultSet rs = st.executeQuery(mysql);
			BGoogleVerification gv = new BGoogleVerification();
			while(rs.next()) {
				String siteName = rs.getString("site_name");		// example = www.shoes.me.ke
				String hostDomain = rs.getString("domain_name");	// shoes.me.ke
				System.out.println("Google to verify the domain : " + hostDomain);

				String OauthToken = "1/ccKDnhlDp36vQMUaFMTkMJezKwYwC_pyOACrapVQWX8";
				String OauthTokenSecret = "GskMH4DghJVI7mKVQMJQEoLw";

				boolean isBeta = false;
				String subdomain = "www";
				String siteToken = rs.getString("google_token");
				System.out.println(siteToken);

				String status = "Failed";
				if(siteToken != null) {
					SiteBuilderService siteBuilderService = new SiteBuilderService(OauthToken, OauthTokenSecret, isBeta);
					String token = siteBuilderService.getVerificationToken(hostDomain, siteToken);
					BVirtualMin vm = new BVirtualMin();
					vm.modifyDomain(hostDomain, token);

					Thread.sleep(2000);

					status = siteBuilderService.link(subdomain, hostDomain, siteToken);
					if(status == null) status = "Failed";
					System.out.println(status);
				}

				if(status.trim().equals("Success")) {
					rs.updateBoolean("google_sync", true);
					rs.updateRow();

					mysql = "INSERT INTO sys_emailed (sys_email_id, table_name, table_id) VALUES (2, 'domains', ";
					mysql += rs.getString("domain_id") + ")";
					Statement stUP = db.createStatement(ResultSet.TYPE_SCROLL_SENSITIVE, ResultSet.CONCUR_UPDATABLE);
					stUP.execute(mysql);
					stUP.close();
				}
			}
			
			rs.close();
			st.close();
			db.close();
		} catch (ClassNotFoundException ex) {
			System.out.println("Class not found : " + ex);
		} catch (SQLException ex) {
			System.out.println("Database connection error : " + ex);
		} catch (GetVerificationTokenException ex) {
			System.out.println("error while getting verification token : " + ex);
		} catch (InterruptedException ex) {
			System.out.println("Sleep error : " + ex);
		}
	}
}

