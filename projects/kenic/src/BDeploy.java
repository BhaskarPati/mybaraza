/**
 * @author      Dennis W. Gichangi <dennis@openbaraza.org>
 * @version     2011.0329
 * @since       1.6
 * website		www.openbaraza.org
 * The contents of this file are subject to the GNU Lesser General Public License
 * Version 3.0 ; you may use this file in compliance with the License.
 */

import java.util.logging.Logger;

import java.util.List;
import java.util.HashMap;
import java.util.Map;
import java.util.Date;

import java.sql.*;

public class BDeploy {
	static Logger log = Logger.getLogger(BDeploy.class.getName());

	public static void main(String args[]) {
		log.info("--------------- Starting Deployed.");

		try {
			String dbpath = "jdbc:postgresql://localhost/epp";
			Connection db = DriverManager.getConnection(dbpath, "postgres", "invent2k");

			String eDelay = getVal(db, "SELECT delay FROM automation WHERE (job_type = 'zone_generation')");
			String eDir = getVal(db, "SELECT value FROM configuration WHERE (name = 'zoneFileDirectory')");
			String eFile = getVal(db, "SELECT ('zones.' || to_char(last_run, 'YYYY.MM.DD.HH') || '00.zip') FROM automation WHERE (job_type = 'zone_file')");

			int delay = Integer.valueOf(eDelay) * 60 * 1000;
			String namedvar = "/var/named/chroot/var/named/ke/";
			String owner = "named:named";

			BUnZip us = new BUnZip(eDir + "/" + eFile, namedvar, owner);
	
			String command = "rndc reload";
			if(command != null) {
				Runtime r = Runtime.getRuntime();
				Process p = r.exec(command);
			}

			db.close();
			log.info("---------- Deployed : " + eFile);
		} catch (SQLException ex) {
			log.severe("Database connection error : " + ex);
		} catch(Exception ex) {
			log.severe("Command run error : " + ex.getMessage());
		}
	}

	public static String getVal(Connection db, String mysql) {
		String ans = null;
		try {
			Statement st = db.createStatement(ResultSet.TYPE_SCROLL_SENSITIVE, ResultSet.CONCUR_UPDATABLE);
			ResultSet rs = st.executeQuery(mysql);
			if(rs.next()) ans = rs.getString(1);

			rs.close();
			st.close();
		} catch (SQLException ex) {
			log.severe("Database connection error : " + ex);
		}

		return ans;
	}
}
