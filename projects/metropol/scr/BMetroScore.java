/**
 * @author      Dennis W. Gichangi <dennis.dichangi@dewcis.com>
 * @version     2011.03.29
 * @since       1.6
 * website		www.dewcis.com
 * The contents of this file are subject to the Dew CIS Solutions License
 * The file should only be shared to Metropol Ltd.
 */
package org.baraza.com;

import java.util.logging.Logger;
import javax.net.ssl.HostnameVerifier;
import javax.net.ssl.HttpsURLConnection;
import javax.net.ssl.SSLContext;
import javax.net.ssl.SSLSession;
import javax.net.ssl.TrustManager;
import javax.net.ssl.X509TrustManager;
import java.security.cert.X509Certificate;
import java.security.NoSuchAlgorithmException;
import java.security.KeyManagementException; 
import java.net.Authenticator;

import org.tempuri.*;

import org.baraza.utils.BLogHandle;

public class BMetroScore {
	Logger log = Logger.getLogger(BMetroScore.class.getName());

	public BMetroScore(BLogHandle logHandle) {
		logHandle.config(log);
	}

	public String getScore(String idNumber) {
		String product = "10101";
		String score = runProcess(idNumber, product);
		if(score != null) score = score.toUpperCase().trim();
		return score;
	}

	public String getReport(String idNumber) {
		String product = "10102";
		String report = runProcess(idNumber, product);
		return report;
	}

	public String runProcess(String idNumber, String product) {
		String mScore = null;

		// Create a trust manager that does not validate certificate chains
		TrustManager[] trustAllCerts = new TrustManager[] {
			new X509TrustManager() {
				public X509Certificate[] getAcceptedIssuers() { return null; } 
				public void checkClientTrusted(X509Certificate[] certs, String authType) { } 
				public void checkServerTrusted( X509Certificate[] certs, String authType) { }
			}
		}; 

		// Install the all-trusting trust manager
		try {
			SSLContext sc = SSLContext.getInstance("SSL"); 
			sc.init(null, trustAllCerts, new java.security.SecureRandom()); 
			HttpsURLConnection.setDefaultSSLSocketFactory(sc.getSocketFactory());
		} catch (NoSuchAlgorithmException ex) {
		} catch (KeyManagementException ex) { }

		try {
			GetProduct service = new GetProduct();
			GetProductSoap port = service.getGetProductSoap12();
			
			mScore = port.getPersonal(idNumber, product);
			System.out.println("SCORE : " + mScore + " for : " + idNumber);
		} catch (Exception ex) {
			System.out.println("Web Remote Exeption : " + ex);
			mScore = null;
		}

		return mScore;
	}
}

