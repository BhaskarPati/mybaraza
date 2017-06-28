import java.util.Map;
import java.util.HashMap;
import java.net.URL;
import java.net.MalformedURLException;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.io.IOException;

public class test {

	public static void main(String args[]) {

		try {
			URL aURL = new URL("https://www.etranzact.net/WebConnectPlus/query.jsp?TERMINAL_ID=0690000082&TRANSDATE=2016-11-16&TRANSDESC=186278;Pay;2016/2017.1;SUDEJO0001&TRANSACTION_ID=DEFAULT");
			System.out.println("host = " + aURL.getHost());
			System.out.println("path = " + aURL.getPath());
			System.out.println("query = " + aURL.getQuery());

			String resp = null;
			String inputLine = null;
			BufferedReader in = new BufferedReader(new InputStreamReader(aURL.openStream()));
			while ((inputLine = in.readLine()) != null) {
				if(inputLine.startsWith("SUCCESS")) resp = inputLine.trim();
			}
			in.close();
			
			Map<String, String> params = new HashMap<String, String>();
			if(resp != null) {
				String srp[] = resp.split("&");
				for(String rp : srp) {
					String pkv[] = rp.split("=");
					if(pkv.length == 2) params.put(pkv[0].trim(), pkv[1].trim());
				}
			}
			
			String sucess = params.get("SUCCESS");
			if(sucess != null) {
				System.out.println("SUCCESS : "  + sucess);
			}
			
			System.out.println(resp);
		} catch(MalformedURLException ex) {
			System.out.println("Malformed URL Exception : " + ex);
		} catch(IOException ex) {
			System.out.println("IO Exception : " + ex);
		}

		System.out.println("Exiting Test mode");
	}
}


