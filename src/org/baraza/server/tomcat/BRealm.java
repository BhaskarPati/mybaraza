/**
 * @author      Dennis W. Gichangi <dennis@openbaraza.org>
 * @version     2011.0329
 * @since       1.6
 * website		www.openbaraza.org
 * The contents of this file are subject to the GNU Lesser General Public License
 * Version 3.0 ; you may use this file in compliance with the License.
 */
package org.baraza.server.tomcat;

import java.util.logging.Logger;
import java.io.File;
import java.security.Principal;
import java.util.ArrayList;
import java.util.List;

import org.apache.catalina.realm.GenericPrincipal;
import org.apache.catalina.realm.RealmBase;

import org.baraza.DB.BDB;
import org.baraza.xml.BElement;
import org.baraza.utils.BCipher;
import org.baraza.utils.BLogHandle;

public class BRealm extends RealmBase {
	Logger log = Logger.getLogger(BTomcat.class.getName());

	private String username;
	private String password;

	@Override
	public Principal authenticate(String username, String credentials) {
		this.username = username;
		this.password = credentials;

		BCipher cp =  new BCipher();

		/* dummy authentication */
		if (this.username.equals(this.password)) {
			return getPrincipal(username);
		} else {
			return null;
		}
	}

	@Override
	protected Principal getPrincipal(String username) {
		List<String> roles = new ArrayList<String>();
		roles.add("user");
		return new GenericPrincipal(username, password, roles);
	}

	@Override
	protected String getPassword(String string) {
		return password;
	}

	@Override
	protected String getName() {
		return username;
	}

	/* Custom variables, see <Realm> element */
	private String myVariable;

	public String getMyVariable() {
		return myVariable;
	}

	public void setMyVariable(String myVariable) {
		this.myVariable = myVariable;
	}
	
}

