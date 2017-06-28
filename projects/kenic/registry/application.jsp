<%@ page import="cx.cocca.registry.configuration.SiteConf" %>
<%@ page import="cx.cocca.utils.HTMLFormat" %>
<%@ page import="cx.cocca.utils.UI" %>
<%@ page import="java.util.List" %>

<jsp:include page="/header.jsp"/>

<% String display = request.getParameter("display"); 

if(display == null) {

%>

<form id="baraza" name="baraza" method="post" action="application">
  <div align='center'><table border="2">
   <tr><td width="500">
	<table id="data" class="dataTable">
		<thead><tr>
		<th width="200"></th>
		<th width="300">Enter Value in space allocated, (* is manditory)</th>
		</tr></thead>
		<tr><td><div align='right'>Company Name * : </div></td><td><input type='text' name='companyname' size='30'></td></tr>
		<tr><td><div align='right'>Address : </div></td><td><input type='text' name='address' size='30'></td></tr>
		<tr><td><div align='right'>Postal Code : </div></td><td><input type='text' name='postalcode' size='30'></td></tr>
		<tr><td><div align='right'>Premises : </div></td><td><input type='text' name='premises' size='30'></td></tr>
		<tr><td><div align='right'>Street : </div></td><td><input type='text' name='street' size='30'></td></tr>
		<tr><td><div align='right'>Town * : </div></td><td><input type='text' name='town' size='30'></td></tr>
		<tr><td><div align='right'>Tel No. * : </div></td><td><input type='text' name='telno' size='30'></td></tr>
		<tr><td><div align='right'>Fax : </div></td><td><input type='text' name='fax' size='30'></td></tr>
		<tr><td><div align='right'>Email * : </div></td><td><input type='text' name='email' size='30'></td></tr>
		<tr><td><div align='right'>PIN Number * : </div></td><td><input type='text' name='pinnumber' size='30'></td></tr>
		<tr><td><div align='right'>NS 1 * : </div></td><td><input type='text' name='ns1' size='30'></td></tr>
		<tr><td><div align='right'>NS 2 * : </div></td><td><input type='text' name='ns2' size='30'></td></tr>
		<tr><td><div align='right'>Admin Contact * : </div></td><td><input type='text' name='admin_contact' size='30'></td></tr>
		<tr><td><div align='right'>Admin E-Mail * : </div></td><td><input type='text' name='admin_email' size='30'></td></tr>
		<tr><td><div align='right'>Billing Contact : </div></td><td><input type='text' name='billing_contact' size='30'></td></tr>
		<tr><td><div align='right'>Billing E-Mail : </div></td><td><input type='text' name='billing_email' size='30'></td></tr>
		<tr><td><div align='right'>Tech Contact : </div></td><td><input type='text' name='tech_contact' size='30'></td></tr>
		<tr><td><div align='right'>Tech E-Mail : </div></td><td><input type='text' name='tech_email' size='30'></td></tr>
		<tr><td><div align='right'>Service Contact : </div></td><td><input type='text' name='service_contact' size='30'></td></tr>
		<tr><td><div align='right'>Service E-Mail : </div></td><td><input type='text' name='service_email' size='30'></td></tr>
		<tr><td><div align='right'>Details : </div></td><td><textarea name='details' cols='30' rows='5'></textarea></td></tr>
	</table>
   </td><td width="300">
		<b>Conditions</b>
		<br><textarea disabled="yes" cols='40' rows='40'><jsp:include page="/conditions.jsp"/></textarea>
		<br>I have read and accepted the conditions <input type='checkbox' name='conditions' size='30'> 
		<br><input name="submit" type="submit" value="Submit"/>
   </td></tr>
  </table></div>
</form>

<% } else { %>

You have Submitted your application.

<% } %>

<div id="navBar"><p>&nbsp;</p></div>

<div id="siteInfo">
<span id="version"><%@include file="version.jsp"%></span><a href="http://www.kenic.or.ke/">&copy; 2009 | KeNIC</a>

</div>
</body>
</html>

