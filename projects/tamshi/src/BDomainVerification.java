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
public class BDomainVerification {
	final String APP_DESCRIPTION = "Site Verification API Java Client Sample";
	final String META_VERIFICATION_METHOD = "DNS";
	final String SITE_TYPE = "INET_DOMAIN";

	public static void main(String args[]) {

		if(args.length == 2) {
			String hostDomain = args[0];	// shoes.me.ke
			String siteName = "www." + args[0];		// example = www.shoes.me.ke
			System.out.println("Google to verify the domain : " + hostDomain);

			String OauthToken = "1/ccKDnhlDp36vQMUaFMTkMJezKwYwC_pyOACrapVQWX8";
			String OauthTokenSecret = "GskMH4DghJVI7mKVQMJQEoLw";

			boolean isBeta = false;
			String subdomain = "www";
			String siteToken = args[1];
			System.out.println(siteToken);

			String status = "Failed";
			try {
				SiteBuilderService siteBuilderService = new SiteBuilderService(OauthToken, OauthTokenSecret, isBeta);
				String token = siteBuilderService.getVerificationToken(hostDomain, siteToken);
				BVirtualMin vm = new BVirtualMin();
				vm.modifyDomain(hostDomain, token);

				Thread.sleep(2000);

				status = siteBuilderService.link(subdomain, hostDomain, siteToken);
				if(status == null) status = "Failed";
				System.out.println(status);
			} catch (GetVerificationTokenException ex) {
				System.out.println("error while getting verification token : " + ex);
			} catch (InterruptedException ex) {
				System.out.println("Sleep error : " + ex);
			}
		} else {
			System.out.println("USAGE java -jar domainverification.jar {domain} {google_code}");
		}
	}
}

