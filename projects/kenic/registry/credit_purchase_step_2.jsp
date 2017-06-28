<%@ page import="cx.cocca.registry.navigation.ClientMenu"%>
<%@ page import="cx.cocca.utils.HTMLFormat"%>
<%@ page import="java.util.ArrayList"%>
<%@ page import="java.sql.Connection"%>
<%@ page import="java.sql.Date"%>
<%@ page import="java.text.SimpleDateFormat"%>
<%@ page import="java.sql.PreparedStatement"%>
<%@ page import="java.sql.ResultSet"%>
<%@ page import="java.util.HashMap"%>
<%@ page import="java.math.BigDecimal"%>
<%@ page import="java.util.Calendar" %>
<%@ page import="cx.cocca.registry.*" %>
<%@ page import="cx.cocca.utils.UI" %>
<%
    Client client = (Client) request.getUserPrincipal();
    SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd");
    sdf.setTimeZone(client.getTimeZone());

        Connection dbc = client.getConnection();
        String roid = normalize(request.getParameter("roid"));
        Client upClient = null;


    try {
        if (roid == null)
            throw new ServletException(UI.tr(client, "client_credit_purchase_no_client", false));

        upClient = new Client(roid, dbc);
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

        //cc details
        String name = normalize(request.getParameter("cct_name"));
        String number = "";
        String cvc = normalize(request.getParameter("cct_cvc"));
        int month = Calendar.getInstance().get(Calendar.MONTH) + 1;
        if (normalize(request.getParameter("cct_expiry_month")) != null)
            month = Integer.parseInt(normalize(request.getParameter("cct_expiry_month")));

        int year = Calendar.getInstance().get(Calendar.YEAR) - 2000;
        if (normalize(request.getParameter("cct_expiry_year")) != null)
            year = Integer.parseInt(normalize(request.getParameter("cct_expiry_year")));

        String visa = ("visa".equals(request.getParameter("cct_type"))) ? " selected " : "";
        String mastercard = ("mastercard".equals(request.getParameter("cct_type"))) ? " selected " : "";
        String kenicpay = ("kenicpay".equals(request.getParameter("cct_type"))) ? " selected " : "";

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

    <% if( request.getAttribute("res_msg") != null) { %>
<h2><%= request.getAttribute("res_msg")%></h2>
    <% } %>

    <%
if (request.getAttribute("errors") != null && ((ArrayList) request.getAttribute("errors")).size() > 0) {
    out.write("<h3>");
    for (Object err : (ArrayList) request.getAttribute("errors")) {
    %>
                <%= err.toString() %><br/>
    <%
    }
    out.write("</h3>");
}
    %>
<form action="credit_purchase_step_1.jsp">
    <input type="hidden" name="roid" value="<%=upClient.getRoid()%>"/>
    <input id="endDate" type="hidden" style="padding-left: 5px;" size="10" name="endDate" value="<%=HTMLFormat.escape(sdf.format(endDate))%>"/>
    <table style="padding-top:25px;margin-top:25px;width:410px;border-top-style:solid;border-bottom-style:solid;
        margin-bottom:25px;padding-bottom:25px;border-width:1px;">
        <tr>
            <th><%= UI.tr(client, "client_credit_purchase_bal_date",false) %></th>
            <td><%=HTMLFormat.escape(sdf.format(endDate))%></td>
        </tr>
    </table>
</form>
<script type="text/javascript" language="JavaScript">

function mod10( cardNumber ) {     // LUHN Formula for validation of credit card numbers.
	var ar = new Array( cardNumber.length );
	var i = 0,sum = 0;

    for( i = 0; i < cardNumber.length; ++i ) {
    	ar[i] = parseInt(cardNumber.charAt(i));
    }
    for( i = ar.length -2; i >= 0; i-=2 ) { // you have to start from the right, and work back.
    	ar[i] *= 2;							 // every second digit starting with the right most (check digit)
    	if( ar[i] > 9 ) ar[i]-=9;			 // will be doubled, and summed with the skipped digits.
    }										 // if the double digit is > 9, ADD those individual digits together
    for( i = 0; i < ar.length; ++i ) {
        sum += ar[i];						 // if the sum is divisible by 10 mod10 succeeds
    }
    return (((sum%10)==0)?true:false);
}

function expired( month, year ) {
    var now = new Date();							// this function is designed to be Y2K compliant.
    var expiresIn = new Date();		                // create an expired on date object with inserted thru expiration date
    expiresIn.setYear(year);
    expiresIn.setMonth(month);
    expiresIn.setDate(1);
    expiresIn.setHours(0);
    expiresIn.setMinutes(0);
    expiresIn.setSeconds(0);
    if( now.getTime() > expiresIn.getTime() ) {
        return true;
    }
    return false;									// then we get the miliseconds, and do a long integer comparison
}


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
            if (e.type == "hidden" && /(\w)+_amount$/.test(e.name)){
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


function validateCard(cardNumber,cardType,cardMonth,cardYear) {
    if( cardNumber.length == 0 ) {						//most of these checks are self explanitory
        alert("<%= UI.tr(client, "client_credit_purchase_card_bad_number",true) %>");
        return false;
    }
    for( var i = 0; i < cardNumber.length; ++i ) {		// make sure the number is all digits.. (by design)
        var c = cardNumber.charAt(i);
        if( c < '0' || c > '9' ) {
            alert("<%= UI.tr(client, "client_credit_purchase_card_number_digits", true) %>");
            return false;
        }
    }
    if( expired( cardMonth, cardYear ) ) {
        alert("<%= UI.tr(client, "client_credit_purchase_card_expired", true) %>");
        return false;
    }

    var length = cardNumber.length;			//perform card specific length and prefix tests
    switch( cardType ) {
        case 'a':
            if( length != 15 ) {
                alert("<%= UI.tr(client, "client_credit_purchase_card_bad_ax", true) %>");
                return false;
            }
            var prefix = parseInt( cardNumber.substring(0,2));
            if( prefix != 34 && prefix != 37 ) {
                alert("<%= UI.tr(client, "client_credit_purchase_card_bad_ax", true) %>");
                return false;
            }
            break;
        case 'd':
            if( length != 16 ) {
                alert("<%= UI.tr(client, "client_credit_purchase_card_bad_disc", true) %>");
                return false;
            }
            var prefix = parseInt( cardNumber.substring(0,4));
            if( prefix != 6011 ) {
                alert("<%= UI.tr(client, "client_credit_purchase_card_bad_disc", true) %>");
                return false;
            }
            break;
        case 'MasterCard':
            if( length != 16 ) {
                alert("<%= UI.tr(client, "client_credit_purchase_card_bad_master", true) %>");
                return false;
            }
            var prefix = parseInt( cardNumber.substring(0,2));
            if( prefix < 51 || prefix > 55) {
                alert("<%= UI.tr(client, "client_credit_purchase_card_bad_master", true) %>");
                return false;
            }
            break;
        case 'VISA':
            if( length != 16 && length != 13 ) {
                alert("<%= UI.tr(client, "client_credit_purchase_card_bad_visa", true) %>");
                return false;
            }
            var prefix = parseInt( cardNumber.substring(0,1));
            if( prefix != 4 ) {
                alert("<%= UI.tr(client, "client_credit_purchase_card_bad_visa", true) %>");
                return false;
            }
            break;
    }

    if( !mod10( cardNumber ) ) { 		// run the check digit algorithm
        alert("<%= UI.tr(client, "client_credit_purchase_card_number_invalid", true) %>");
        return false;
    }
    return true; // at this point card has not been proven to be invalid
}
</script>

<script type="text/javascript" language="JavaScript">
function validateCheckout(frm) {
  if (frm.cct_name.value == "") {
    alert("<%= UI.tr(client, "client_credit_purchase_card_name_none", true) %>");
    frm.cct_name.focus();
    return false;
  }
  if (frm.cct_number.value == "") {
    alert("<%= UI.tr(client, "client_credit_purchase_card_number_none", true) %>");
    frm.cct_number.focus();
    return false;
  }
  if (frm.cct_type.value == "") {
    alert("<%= UI.tr(client, "client_credit_purchase_card_type_none", true) %>");
    frm.cct_type.focus();
    return false;
  }
  if (frm.cct_expiry_month.value == "") {
    alert("<%= UI.tr(client, "client_credit_purchase_card_expiry_month_none", true) %>");
    frm.cct_expiry_month.focus();
    return false;
  }
  if (frm.cct_expiry_year.value == "") {
    alert("<%= UI.tr(client, "client_credit_purchase_card_expiry_year_none", true) %>");
    frm.cct_expiry_year.focus();
    return false;
  }

    if (frm.cct_cvc.value == "") {
      alert("<%= UI.tr(client, "client_credit_purchase_card_cvc_none", true) %>");
      frm.cct_cvc.focus();
      return false;
    }

  if (findTotal(frm) < 1){
      alert("<%= UI.tr(client, "client_credit_purchase_bad_min_total", true) %>");
      return false;
  }
  var year = "20" + frm.cct_expiry_year.value;
  return validateCard(frm.cct_number.value, frm.cct_type.value, frm.cct_expiry_month.value, year);
}

</script>
<form action="credit_save.jsp" method="post" onsubmit="return validateCheckout(this)">
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
                    <td><%=vals[0]%> <%= tc.getCurrency()%></td>

                </tr>
                <tr>
                    <th><%= UI.tr(client, "client_credit_purchase_amt",false) %></th>
                    <td>
                        <%
                            if (tc.allowPurchase()){
                                numAllowed++;
                        %>
                        <%= request.getParameter(tld + "_amount") %>
                        <%= tc.getCurrency()%>
                        <input type="hidden" name="<%= tld %>_amount" value="<%= request.getParameter(tld + "_amount") %>">
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

<%
    String description = request.getParameter("description");

    if(description != null && !description.trim().equals("")) {
%>
    <table style="width:410px;border-bottom-style:solid;margin-bottom:25px;padding-bottom:25px;border-width:1px;">
        <tbody>
            <tr>
                <th><%= UI.tr(client, "client_credit_purchase_pay_desc",false) %></th>
                <td><%= request.getParameter("description") %><input type="hidden" name="description"
                                                                     value="<%= request.getParameter("description") %>"></td>

            </tr>
        </tbody>
    </table>
<%
    }
%>


    <table style="width:410px;border-bottom-style:solid;margin-bottom:25px;padding-bottom:25px;border-width:1px;">
        <thead>
            <tr>
                <th colspan="2" style="padding-bottom:15px;">
                    <%= UI.tr(client, "client_credit_purchase_card_details",false) %>
                </th>
            </tr>
        </thead>
        <tr>
            <th scope="row"><%= UI.tr(client, "client_credit_purchase_card_type",false) %></th>
            <td>
                <select name="cct_type">
					<option <%= kenicpay %> value="KENICPAY">KENICPAY</option>
                    <option <%= visa %> value="VISA"><%= UI.tr(client, "client_credit_purchase_visa",false) %></option>
                    <option <%= mastercard %> value="MasterCard"><%= UI.tr(client, "client_credit_purchase_mastercard",false) %></option>
                </select>
                <span>*</span>
            </td>
        </tr>
        <tr>
            <th>
                <%= UI.tr(client, "client_credit_purchase_card_name",false) %>
            </th>
            <td>
                <input type="text" size="30" name="cct_name" value="<%= HTMLFormat.escape(name) %>"/>
                <span>*</span>
            </td>
        </tr>
        <tr>
            <th>
                <%= UI.tr(client, "client_credit_purchase_card_num",false) %>
            </th>
            <td>
                <input type="text" name="cct_number" value="<%= number %>"/>
                <span>*</span>
            </td>
        </tr>
        <tr>
             <th>
                 <%= UI.tr(client, "client_credit_purchase_card_expiry",false) %>
             </th>
            <td>
                <select class="input" name="cct_expiry_month">
                    <option value=""></option>
                    <option <%= (month == 1) ? "selected " : "" %>value="01">01: <%= UI.tr(client, "jan",false) %></option>
                    <option <%= (month == 2) ? "selected " : "" %>value="02">02: <%= UI.tr(client, "feb",false) %></option>
                    <option <%= (month == 3) ? "selected " : "" %>value="03">03: <%= UI.tr(client, "mar",false) %></option>
                    <option <%= (month == 4) ? "selected " : "" %>value="04">04: <%= UI.tr(client, "apr",false) %></option>
                    <option <%= (month == 5) ? "selected " : "" %>value="05">05: <%= UI.tr(client, "may",false) %></option>
                    <option <%= (month == 6) ? "selected " : "" %>value="06">06: <%= UI.tr(client, "jun",false) %></option>
                    <option <%= (month == 7) ? "selected " : "" %>value="07">07: <%= UI.tr(client, "jul",false) %></option>
                    <option <%= (month == 8) ? "selected " : "" %>value="08">08: <%= UI.tr(client, "aug",false) %></option>
                    <option <%= (month == 9) ? "selected " : "" %>value="09">09: <%= UI.tr(client, "sep",false) %></option>
                    <option <%= (month == 10) ? "selected " : "" %>value="10">10: <%= UI.tr(client, "oct",false) %></option>
                    <option <%= (month == 11) ? "selected " : "" %>value="11">11: <%= UI.tr(client, "nov",false) %></option>
                    <option <%= (month == 12) ? "selected " : "" %>value="12">12: <%= UI.tr(client, "dec",false) %></option>
                </select>
                <select class="input" name="cct_expiry_year">
                    <option value=""></option>
                    <option <%= (year == 6) ? "selected " : "" %>value="06">2006</option>
                    <option <%= (year == 7) ? "selected " : "" %>value="07">2007</option>
                    <option <%= (year == 8) ? "selected " : "" %>value="08">2008</option>
                    <option <%= (year == 9) ? "selected " : "" %>value="09">2009</option>
                    <option <%= (year == 10) ? "selected " : "" %>value="10">2010</option>
                    <option <%= (year == 11) ? "selected " : "" %>value="11">2011</option>
                    <option <%= (year == 12) ? "selected " : "" %>value="12">2012</option>
                    <option <%= (year == 13) ? "selected " : "" %>value="13">2013</option>
                    <option <%= (year == 14) ? "selected " : "" %>value="14">2014</option>
                    <option <%= (year == 15) ? "selected " : "" %>value="15">2015</option>
                    <option <%= (year == 16) ? "selected " : "" %>value="16">2016</option>
                    <option <%= (year == 17) ? "selected " : "" %>value="17">2017</option>
                    <option <%= (year == 18) ? "selected " : "" %>value="18">2018</option>
                    <option <%= (year == 19) ? "selected " : "" %>value="19">2019</option>
                    <option <%= (year == 20) ? "selected " : "" %>value="20">2020</option>
                </select>
                <span>*</span>
            </td>
        </tr>
        <tr>
            <th>
                <%= UI.tr(client, "client_credit_purchase_cvc",false) %>
            </th>
            <td>
                <input type="text" name="cct_cvc" size="4" value="<%= HTMLFormat.escape(cvc) %>"/>
                <span>* <%= UI.tr(client, "client_credit_purchase_cvc_help",false) %></span>
            </td>
        </tr>

    </table>
<input type="submit" value="<%= UI.tr(client, "client_credit_purchase_submit",false) %>" />
<%
    }
%>

</form>


<%
    request.setAttribute("menu",new ClientMenu(upClient,client,request.getContextPath()));
%>
<jsp:include page="/footer.jsp"/>

<%
    }finally{
        if (dbc != null) dbc.close();
    }
%>

<%!
    public String normalize(String in){
        if (in == null) return in;
        in = in.trim();
        if (in.length() == 0) return in;
        return in;
    }
%>
