<%@ page import="cx.cocca.registry.configuration.SiteConf" %>
<%@ page import="cx.cocca.utils.HTMLFormat" %>
<%@ page import="cx.cocca.utils.UI" %>
<%@ page import="java.text.DecimalFormat" %>
<%@ page import="dewcis.DB.DDB" %>
<%@ page import="java.sql.*" %>

<jsp:include page="/header.jsp"/>

<% 
	String mysql1 = "SELECT zone.holdtoverify, count(domain.name) as domaincount ";
	mysql1 += "FROM domain INNER JOIN zone ON domain.zone = zone.name ";
	mysql1 += "WHERE (domain.zone <> 'ke') ";
	mysql1 += "GROUP BY zone.holdtoverify; ";

	String mysql2 = "SELECT zone.holdtoverify, UPPER(domain.zone) as zone, count(domain.name) as domaincount ";
	mysql2 += "FROM domain INNER JOIN zone ON domain.zone = zone.name ";
	mysql2 += "WHERE (domain.zone <> 'ke') ";
	mysql2 += "GROUP BY zone.holdtoverify, domain.zone ";
	mysql2 += "ORDER BY domain.zone;";

	String mysql3 = "SELECT count(domain.name) as domaincount ";
	mysql3 += "FROM domain INNER JOIN zone ON domain.zone = zone.name ";
	mysql3 += "WHERE (domain.zone <> 'ke') AND (createdate > now() - interval '1 day');";

	String mysql4 = "SELECT count(domain.name) as domaincount ";
	mysql4 += "FROM domain INNER JOIN zone ON domain.zone = zone.name ";
	mysql4 += "WHERE (domain.zone <> 'ke') AND (createdate > now() - interval '30 day')";

	String mysql5 = "SELECT count(domain.name) as domaincount ";
	mysql5 += "FROM domain INNER JOIN zone ON domain.zone = zone.name ";
	mysql5 += "WHERE (domain.zone <> 'ke') AND (renewaldate > now() - interval '1 day');";

	String mysql6 = "SELECT count(domain.name) as domaincount ";
	mysql6 += "FROM domain INNER JOIN zone ON domain.zone = zone.name ";
	mysql6 += "WHERE (domain.zone <> 'ke') AND (renewaldate > now() - interval '30 day')";

	DDB db =  new DDB();
	db.openDatabase();
	ResultSet rs1 = db.readQuery(mysql1);
	ResultSet rs2 = db.readQuery(mysql2);
	ResultSet rs3 = db.readQuery(mysql3);
	ResultSet rs4 = db.readQuery(mysql4);
	ResultSet rs5 = db.readQuery(mysql5);
	ResultSet rs6 = db.readQuery(mysql6);

	int gdomain = 0;
	int rdomain = 0;
	DecimalFormat myFormatter = new DecimalFormat("##0.00");

	String rdata1 = "";
	String ldata1 = "";

	String rdata2 = "<table><tr><td colspan=\"4\" align=\"center\">RESTRICTED</td></tr>";
	String ldata2 = "<table><tr><td colspan=\"4\" align=\"center\">GENERIC</td></tr>";
	try {
		while(rs1.next()) {
			if(rs1.getBoolean("holdtoverify")) rdomain += rs1.getInt("domaincount");
			else gdomain +=  rs1.getInt("domaincount");
		}

		while(rs2.next()) {
			if(rs2.getBoolean("holdtoverify")) {
				rdata2 += "<tr><td width=\"75\">" + rs2.getString("zone") + "</td><td width=\"75\">" + rs2.getString("domaincount");
				rdata2 += "</td><td align=\"right\">";
				rdata2 += myFormatter.format(100 * rs2.getFloat("domaincount") / (gdomain + rdomain)).toString() + "</td></tr>";
			} else {
				ldata2 += "<tr><td width=\"75\">" + rs2.getString("zone") + "</td><td width=\"75\">" + rs2.getString("domaincount");
				ldata2 += "</td><td align=\"right\">";
				ldata2 += myFormatter.format(100 * rs2.getFloat("domaincount") / (gdomain + rdomain)).toString() + "</td></tr>";
			}
		}
		rdata2 += "<tr><td>Total</td><td>" + Integer.valueOf(rdomain).toString() +  "</td><td>";
		rdata2 += myFormatter.format(100 * Float.valueOf(rdomain) / (gdomain + rdomain)).toString() + "</td><td></td></tr></table>";
		ldata2 += "<tr><td>Total</td><td>" + Integer.valueOf(gdomain).toString() +  "</td><td>";
		ldata2 += myFormatter.format(100 * Float.valueOf(gdomain) / (gdomain + rdomain)).toString() + "</td><td></td></tr></table>";

		rs3.next();
		rs4.next();
		rs5.next();
		rs6.next();
	} catch (SQLException ex) {
		System.err.println("Database transaction get data error : " + ex);
	}
	
	db.closeDatabase();
%>


<div align='center'>

  <table border="2">
		<tr><td colspan="2"><div align='left'>Registered Domains per TLD - <%= new java.util.Date() %></div></td></tr>
		<tr><td width="250" align="left" valign="top"><div align='left'><%= rdata2 %></div></td>
			<td width="250" align="left" valign="top"><div align='left'><%= ldata2 %></div></td></tr>
		<tr><td colspan="2"><div align='left'>Total domains are <%= Integer.valueOf(rdomain + gdomain).toString() %></div></td></tr>
		<tr><td colspan="2"><div align='left'>Total domains registered within 24 Hours <%= rs3.getString("domaincount") %></div></td></tr>
		<tr><td colspan="2"><div align='left'>Total domains registered within 30 Days <%= rs4.getString("domaincount") %></div></td></tr>
		<tr><td colspan="2"><div align='left'>Total domains renewed within 24 Hours <%= rs5.getString("domaincount") %></div></td></tr>
		<tr><td colspan="2"><div align='left'>Total domains renewed within 30 Days <%= rs6.getString("domaincount") %></div></td></tr>
  </table>

</div>

<br>

<div id="siteInfo">
<span id="version"><%@include file="version.jsp"%></span><a href="http://www.kenic.or.ke/">&copy; 2009 | KeNIC</a>
</div>
</div>

</body>
</html>

