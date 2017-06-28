<%@ page import="cx.cocca.registry.Client"%>
<%@ page import="cx.cocca.registry.Login"%>
<%@ page import="cx.cocca.registry.RegistrarAccess"%>
<%@ page import="cx.cocca.registry.Tld"%>
<%@ page import="cx.cocca.registry.TldCurrency"%>
<%@ page import="cx.cocca.registry.navigation.ClientMenu"%>
<%@ page import="cx.cocca.utils.HTMLFormat"%>
<%@ page import="cx.cocca.utils.JDBCUtil"%>
<%@ page import="cx.cocca.utils.UI"%>
<%@ page import="java.math.BigDecimal"%>
<%@ page import="java.sql.Connection" %>
<%@ page import="java.sql.Date" %>
<%@ page import="java.sql.PreparedStatement" %>
<%@ page import="java.sql.ResultSet" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%@ page import="static cx.cocca.utils.HTMLFormat.normalize" %>
<%@ page import="java.util.EnumSet" %>
<%@ page import="java.util.HashMap" %>
<%@ page import="java.util.List" %>
<%
    Login login = (Login) request.getUserPrincipal();
    Client client = login.getClient();

    if(! client.isAdminOfAnySort() && !login.isMemberOf(EnumSet.of(Login.Role.MASTER, Login.Role.FINANCE))) {
        response.sendRedirect("view.jsp");
        return;
    }

    String message = (String) request.getAttribute("res_msg");
    List<String> errors = (List<String>) request.getAttribute("errors");

    SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd");
    sdf.setTimeZone(client.getTimeZone());

    Connection dbc = client.getConnection();
    String roid = normalize(request.getParameter("roid"));

    if(roid == null) {
        roid = client.getRoid();
    }

    Client upClient;
    try {
        if (roid == null)
            throw new ServletException(UI.tr(client, "client_credit_purchase_no_client", false));

        upClient = new Client(dbc, roid);
        if (!upClient.isValid())
            throw new ServletException(UI.tr(client, "client_credit_purchase_bad_client", false));

        Date endDate = null;
        try {
            endDate = new Date(sdf.parse(request.getParameter("endDate")).getTime());
        } catch (Exception e) {
        }
        if (endDate == null)
            endDate = new Date(new java.util.Date().getTime());

        HashMap<String, BigDecimal[]> tldToBalance = new HashMap<String, BigDecimal[]>();
        for (RegistrarAccess ra : upClient.getRegistrarAccessList()) {
            String tname = Tld.longestMatch(ra.getZoneName()).getTld();
            if (tldToBalance.get(tname) != null)
                continue;
            BigDecimal[] vals = new BigDecimal[]{BigDecimal.ZERO, BigDecimal.ZERO};
            vals[1] = upClient.findTldCreditLimit(tname);
            tldToBalance.put(tname, vals);
        }

        String balance_query = "select sum(total) as balance, tld from ledger where client_roid = ? and created::Date <= ? group by tld order by tld";
        PreparedStatement balanceSt = dbc.prepareStatement(balance_query);
        try {
            balanceSt.setString(1, upClient.getRoid());
            balanceSt.setDate(2, endDate);
            ResultSet rs = balanceSt.executeQuery();
            while (rs.next()) {
                BigDecimal[] vals = tldToBalance.get(rs.getString("tld"));
                if (vals == null) {
                    vals = new BigDecimal[]{BigDecimal.ZERO, BigDecimal.ZERO};
                    tldToBalance.put(rs.getString("tld"), vals);
                }
                vals[0] = rs.getBigDecimal("balance").negate();
            }
        } finally {
            if (balanceSt != null)
                balanceSt.close();
        }

%>

<jsp:include page="/header.jsp">
    <jsp:param name="pageName" value="<%= UI.trformatted(client, "client_credit_purchase_header_template", upClient.getName(), false) %>" />
</jsp:include>

<%
    if (message != null) {
        out.print("<h2>");
        out.print(message);
        out.print("</h2>");
    }

    if (errors != null && !errors.isEmpty()) {
        out.write("<div class=\"errors\">");
        for (String error:errors) {
            out.print("<h3>");
            out.print(error);
            out.print("</h3>");
        }
        out.write("</div>");
    }
%>
<form action="credit_purchase_step_1.jsp">
    <input type="hidden" name="roid" value="<%=upClient.getRoid()%>"/>
    <table style="padding-top:25px;margin-top:25px;width:410px;border-top-style:solid;border-bottom-style:solid;
        margin-bottom:25px;padding-bottom:25px;border-width:1px;">
        <tr>
            <th><label for="endDate"><%= UI.tr(client, "client_credit_purchase_bal_date",false) %></label></th>
            <td><input id="endDate" type="text" style="padding-left: 5px;" size="10" name="endDate" value="<%=HTMLFormat.escape(sdf.format(endDate))%>"/>
    <img src="<%= request.getContextPath()%>/images/calendar.png" height="20" style="margin-bottom: -6px"
         alt="<%= UI.tr(client, "client_credit_purchase_date_sel_alt",false) %>" onclick="displayDatePicker('endDate')"/></td>
            <td><input type="submit" value="<%= UI.tr(client, "client_credit_purchase_date_sel_submit",false) %>" style="margin-left:15px;"/></td>
        </tr>
    </table>
</form>
<script type="text/javascript" language="JavaScript">

    function formatCurrency(num) {
        num = num.toString().replace(/\$|\,/g,'');
        if(isNaN(num))
            num = "0";
        if (num != Math.abs(num)){
            num = 0;
        }
        sign = (num == (num = Math.abs(num)));
        num = Math.floor(num*100+0.50000000001);
        cents = num%100;
        num = Math.floor(num/100).toString();
        if(cents<10)
            cents = "0" + cents;
        for (var i = 0; i < Math.floor((num.length-(1+i))/3); i++)
            num = num.substring(0,num.length-(4*i+3))+','+
                  num.substring(num.length-(4*i+3));
        //return (((sign)?'':'-') + '$' + num + '.' + cents);
        return (((sign)?'':'-') +  num + '.' + cents);
    }


    function findTotal(frm){
        var total = 0;
        var els = frm.elements;
        for(i = 0; i < els.length; i++){
            e = els[i];
            if (e.type == "text" && /(\w)+_amount$/.test(e.name)){
                num = e.value.replace(/\$|\,/g,'');
                if ( !isNaN(parseFloat(num)) ){
                    total += parseFloat(num);
                }
            }
        }
        return total;
    }

    function changeTotal(frm){
        var total = 0;
        var els = frm.elements;
        //var els = document.forms[1].elements;
        for(i = 0; i < els.length; i++){
            e = els[i];
            if (e.type == "text" && /(\w)+_amount$/.test(e.name)){
                num = e.value.replace(/\$|\,/g,'');
                if ( !isNaN(parseFloat(num)) && (parseFloat(num) > 0) ){
                    total += parseFloat(num);
                }
                e.value = formatCurrency(num);
            }
        }
        //document.getElementsByName("total")[0].value = formatCurrency(total);
        document.getElementById("total").innerHTML = formatCurrency(total);
    }

    function validatePage(frm) {
        if (findTotal(frm) < 1) {
          alert("<%= UI.tr(client, "client_credit_purchase_bad_min_total", true) %>");
          return false;
        }
        return true;
    }

</script>


<form action="credit_purchase_step_2.jsp" method="post" onsubmit="return validatePage(this)">
<input type="hidden" name="roid" value="<%=upClient.getRoid()%>"/>
<input type="hidden" name="action" value="payment"/>

<table style="width:410px;border-bottom-style:solid;margin-bottom:25px;padding-bottom:25px;border-width:1px;">
   <%
        BigDecimal total = BigDecimal.ZERO;
        int numAllowed = 0;
        for (String tld : tldToBalance.keySet()){
            TldCurrency tc = upClient.getTldCurrency(tld);
            BigDecimal[] vals = tldToBalance.get(tld);
            if (vals[0].compareTo(BigDecimal.ZERO) == -1)
                total = total.add(vals[0].negate());
    %>
    <tr>
        <th><%=tld%> <%= UI.tr(client, "client_credit_purchase_tld",false) %></th>
        <td>
            <table style="margin-top:-5px;">
                <tr>
                    <th><%= UI.tr(client, "client_credit_purchase_bal",false) %></th>
                    <td><%=vals[0]%> <%= tc.getCurrency() %></td>
                </tr>
                <tr>
                    <th><%= UI.tr(client, "client_credit_purchase_amt",false) %></th>
                    <td>
                        <%
                            if (tc.allowPurchase()){
                                numAllowed++;
                        %>
                        <input type="text" size="10" name="<%=tld+"_amount"%>" onchange="changeTotal(this.form);"
                               value="<%=(vals[0].compareTo(BigDecimal.ZERO) == -1 ? vals[0].negate() : BigDecimal.ZERO)%>"/>
                        <%= tc.getCurrency()%>
                        <%
                            }else{
                        %>
                            <i><%= UI.tr(client, "client_credit_purchase_not_allowed",false) %></i>
                        <%
                            }
                        %>
                    </td>
                </tr>
            </table>
        </td>
    </tr>
    <%
        }
        if (tldToBalance.keySet().size() == 0){
    %>
    <tr>
        <th colspan="2">
            <%= UI.tr(client, "client_credit_purchase_no_tlds",false) %>
        </th>
    </tr>

    <%
        }
    %>
</table>


<%
    if (numAllowed > 0){
%>

<table style="width:410px;border-bottom-style:solid;margin-bottom:25px;padding-bottom:25px;border-width:1px;">
    <tbody>
        <tr>
            <th><label for="desc"><%= UI.tr(client, "client_credit_purchase_pay_desc",false) %></label></th>
            <td><input id="desc" type="text" size="30" name="description"/></td>
        </tr>
    </tbody>
</table>

<%
    }
%>

</form>


<%
    request.setAttribute("menu",new ClientMenu(upClient, login, request.getContextPath()));
%>
<jsp:include page="/footer.jsp"/>

<%
    }finally{
        JDBCUtil.safeClose(dbc);
    }
%>
