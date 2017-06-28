<HTML>
<HEAD>
   <TITLE>Baraza Projects</TITLE>
</HEAD>
<BODY>

<% 
	String appPath = "http://" + request.getLocalAddr() + ":" + request.getLocalPort() + request.getRequestURI() + "projects/"; 
	String dbpath = "jdbc:postgresql://" + request.getLocalAddr() + "/hr";
	String mode = request.getParameter("mode");
	if(mode == null) mode = "run";
	appPath = appPath.replace("index.jsp", "");
%>

<APPLET code="org.baraza.com.BOBCheque" archive="baraza.jar" width="940" height="590">
	<PARAM NAME="config" VALUE="<%= appPath %>"></PARAM>
	<PARAM NAME="mode" VALUE="<%= mode %>"></PARAM>
	<PARAM NAME="dbpath" VALUE="<%= dbpath %>"></PARAM>
</APPLET>
<HR WIDTH="100%">
<a href="app.jsp">Launch the application</a> | <a href="index.jsp?mode=ide">IDE</a></br> | <a href="app.jsp?mode=ide">IDE Application</a></br>
<P><I>Developed by DEW CIS Solutions Ltd - Kenya</I></P>
</BODY>
</HTML>
