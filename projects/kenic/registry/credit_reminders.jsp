<%@ page import="cx.cocca.registry.Client" %>
<%@ page import="cx.cocca.registry.ClientTldCreditNotification" %>
<%@ page import="cx.cocca.registry.Login" %>
<%@ page import="cx.cocca.registry.RegistrarAccess" %>
<%@ page import="cx.cocca.registry.Tld" %>
<%@ page import="cx.cocca.registry.TldCurrency" %>
<%@ page import="cx.cocca.registry.navigation.ClientMenu" %>
<%@ page import="cx.cocca.utils.JDBCUtil" %>
<%@ page import="cx.cocca.utils.UI" %>
<%@ page import="java.math.BigDecimal" %>
<%@ page import="java.sql.Connection" %>
<%@ page import="java.sql.PreparedStatement" %>
<%@ page import="java.sql.ResultSet" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%@ page import="static cx.cocca.utils.HTMLFormat.normalize" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.util.EnumSet" %>
<%@ page import="java.util.HashMap" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Map" %>
<%!
    private static final String MAIN_EMAIL_SELECTION = "main";
    private static final String BILLING_EMAIL_SELECTION = "billing";
    private static final String CUSTOM_EMAIL_SELECTION = "custom";
    private static final String PER_TLD_EMAIL_SELECTION = "per_tld";
%>
<%
    Login login = (Login) request.getUserPrincipal();
    Client client = login.getClient();

    if(! client.isAdminOfAnySort() && !login.isMemberOf(EnumSet.of(Login.Role.MASTER, Login.Role.FINANCE))) {
        response.sendRedirect("view.jsp");
        return;
    }

    SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd");
    sdf.setTimeZone(client.getTimeZone());

    String message = null;
    List<String> errors = new ArrayList<String>();

    Connection dbc = client.getConnection();
    String roid = normalize(request.getParameter("roid"));
    if(roid == null) {
        roid = client.getRoid();
    }
    Client upClient;

    try {
        if (roid == null)
            throw new ServletException(UI.tr(client, "credit_reminder_error_no_client", false));

        upClient = new Client(dbc, roid);
        if (!upClient.isValid())
            throw new ServletException(UI.tr(client, "credit_reminder_error_no_client", false));

        String emailSelection = MAIN_EMAIL_SELECTION;
        String email = null;
        Map<String, BigDecimal[]> tldToBalance = new HashMap<String, BigDecimal[]>();
        Map<String, ClientTldCreditNotification> notificationSettings = new HashMap<String, ClientTldCreditNotification>();

        if("post".equalsIgnoreCase(request.getMethod())) {
            emailSelection = request.getParameter("emailSelection");
            for (RegistrarAccess ra : upClient.getRegistrarAccessList()) {
                String tname = Tld.longestMatch(ra.getZoneName()).getTld();
                if (tldToBalance.get(tname) != null) {
                    continue;
                }

                BigDecimal[] vals = new BigDecimal[]{BigDecimal.ZERO, BigDecimal.ZERO};
                vals[1] = upClient.findTldCreditLimit(tname);
                tldToBalance.put(tname, vals);
                String frequency = normalize(request.getParameter(tname + "_frequency"));

                ClientTldCreditNotification notificationConfig = new ClientTldCreditNotification();
                notificationConfig.setClid(upClient.getClId());
                notificationConfig.setTld(tname);
                notificationConfig.setFrequency(ClientTldCreditNotification.NotificationFrequency.valueOf(frequency));

                try {
                    String threshold = normalize(request.getParameter(tname + "_threshold"));
                    if (threshold != null) {
                        BigDecimal numericThreshold = new BigDecimal(threshold);
                        notificationConfig.setThreshold(numericThreshold);
                        if (numericThreshold.compareTo(vals[1].negate()) < 0) {
                            errors.add(UI.trformatted(client, "credit_reminder_error_threshold_unreachable", new Object[]{tname, vals[1].negate()}, false));
                        }
                    }
                } catch(NumberFormatException e) {
                    errors.add(UI.trformatted(client, "credit_reminder_error_threshold_invalid", tname, false));
                }

                if(PER_TLD_EMAIL_SELECTION.equals(emailSelection)) {
                    notificationConfig.setEmail(normalize(request.getParameter(tname + "_email")));
                } else if(CUSTOM_EMAIL_SELECTION.equals(emailSelection)) {
                    email = normalize(request.getParameter("custom"));
                    notificationConfig.setEmail(normalize(request.getParameter("custom")));
                } else if(BILLING_EMAIL_SELECTION.equals(emailSelection)) {
                    notificationConfig.setEmail(upClient.getBillingEmail());
                } else {
                    notificationConfig.setEmail(upClient.getEmail());
                }

                if(errors.isEmpty()) {
                    notificationConfig.save(dbc);
                }
                notificationSettings.put(tname, notificationConfig);
            }
        } else {
            for (RegistrarAccess ra : upClient.getRegistrarAccessList()) {
                String tname = Tld.longestMatch(ra.getZoneName()).getTld();
                if (tldToBalance.get(tname) != null) {
                    continue;
                }
                ClientTldCreditNotification notificationConfig = ClientTldCreditNotification.findForClientAndTld(dbc, upClient.getClId(), tname);
                BigDecimal[] vals = new BigDecimal[]{BigDecimal.ZERO, BigDecimal.ZERO};
                vals[1] = upClient.findTldCreditLimit(tname);
                tldToBalance.put(tname, vals);
                if(notificationConfig != null) {
                    notificationSettings.put(tname, notificationConfig);
                    if(notificationConfig.getEmail() != null) {
                        if(email == null) {
                            email = notificationConfig.getEmail();
                            if(email.equals(client.getEmail())) {
                                // no change, just stop the case where the main email == the billing email
                            } else if(email.equals(client.getBillingEmail())) {
                                emailSelection = BILLING_EMAIL_SELECTION;
                            } else {
                                emailSelection = CUSTOM_EMAIL_SELECTION;
                            }
                        } else {
                            if(! email.equals(notificationConfig.getEmail())) {
                                emailSelection = PER_TLD_EMAIL_SELECTION;
                            }
                        }
                    }
                }
            }
        }

        String balance_query = "select sum(total) as balance, tld from ledger where client_roid = ? group by tld order by tld";
        PreparedStatement balanceSt = dbc.prepareStatement(balance_query);
        try {
            balanceSt.setString(1, upClient.getRoid());
            ResultSet rs = balanceSt.executeQuery();
            while (rs.next()) {
                BigDecimal[] vals = tldToBalance.get(rs.getString("tld"));
                if (vals == null) {
                    continue;
                }
                vals[0] = rs.getBigDecimal("balance").negate();
            }
        } finally {
            if (balanceSt != null)
                balanceSt.close();
        }
%>

<jsp:include page="/header.jsp">
    <jsp:param name="pageName"
               value="<%= UI.trformatted(client, "credit_reminder_header_template", upClient.getName(), false) %>"/>
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
<script type="text/javascript" language="JavaScript">
<!--
    function emailSelectionChanged() {
        if($('per_tld').checked) {
            $$('tr[class="per_tld_email"]').invoke("show");
        } else {
            $$('tr[class="per_tld_email"]').invoke("hide");
        }

        if($('custom').checked) {
            $('customText').enable();
        } else {
            $('customText').disable();
        }
    }
// -->
</script>

<form action="credit_reminders.jsp" method="post">
    <input type="hidden" name="roid" value="<%=upClient.getRoid()%>"/>

    <table style="width:600px;border-bottom-style:solid;margin-bottom:25px;padding-bottom:25px;border-width:1px;">
        <tr>
            <td><input type="radio" name="emailSelection" id="main" value="main" onclick="emailSelectionChanged(); return true;" <%= MAIN_EMAIL_SELECTION.equals(emailSelection) ? "checked" : "" %>></td>
            <td><label for="main"><%= UI.trformatted(client, "credit_reminder_use_main_email_address", upClient.getEmail(), false) %></label></td>
        </tr>
        <%
            if(upClient.getBillingEmail() != null && !upClient.getBillingEmail().trim().isEmpty()) {
        %>
        <tr>
            <td><input type="radio" name="emailSelection" id="billing" value="billing" onclick="emailSelectionChanged(); return true;" <%= BILLING_EMAIL_SELECTION.equals(emailSelection) ? "checked" : "" %>></td>
            <td><label for="billing"><%= UI.trformatted(client, "credit_reminder_use_billing_email_address", upClient.getBillingEmail(), false) %></label></td>
        </tr>
        <%
            }
        %>
        <tr>
            <td><input type="radio" name="emailSelection" id="custom" value="custom" onclick="emailSelectionChanged(); return true;" <%= CUSTOM_EMAIL_SELECTION.equals(emailSelection) ? "checked" : "" %>></td>
            <td><label for="custom"><%= UI.tr(client, "credit_reminder_use_specified_email_address") %></label></td>
        </tr>
        <tr>
            <td>&nbsp;</td>
            <td><input type="text" name="custom" id="customText" value="<%= CUSTOM_EMAIL_SELECTION.equals(emailSelection) ? (email == null ? "" : email) : "" %>" <%= CUSTOM_EMAIL_SELECTION.equals(emailSelection) ? "" : "disabled='true'" %>></td>
        </tr>
        <tr>
            <td><input type="radio" name="emailSelection" id="per_tld" value="per_tld" onclick="emailSelectionChanged(); return true;" <%= PER_TLD_EMAIL_SELECTION.equals(emailSelection) ? "checked" : "" %>></td>
            <td><label for="per_tld"><%= UI.tr(client, "credit_reminder_use_different_email_per_tld") %></label></td>
        </tr>
    </table>



    <table style="width:600px;border-bottom-style:solid;margin-bottom:25px;padding-bottom:25px;border-width:1px;">
        <%
            BigDecimal total = BigDecimal.ZERO;
            for (String tld : tldToBalance.keySet()) {
                TldCurrency tc = upClient.getTldCurrency(tld);
                BigDecimal[] vals = tldToBalance.get(tld);
                if (vals[0].compareTo(BigDecimal.ZERO) == -1) {
                    total = total.add(vals[0].negate());
                }

                ClientTldCreditNotification notificationConfig = notificationSettings.get(tld);
                if(notificationConfig == null) {
                    notificationConfig = new ClientTldCreditNotification();
                }
        %>
        <tr>
            <th><%=tld%> <%= UI.tr(client, "credit_reminder_tld_label", false) %>
            </th>
            <td>
                <table style="margin-top:-5px;">
                    <tr>
                        <th><%= UI.tr(client, "credit_reminder_current_balance_label", false) %>
                        </th>
                        <td><%=vals[0]%> <%= tc.getCurrency() %>
                        </td>
                    </tr>
                    <tr>
                        <th><%= UI.tr(client, "credit_reminder_credit_limit_label", false) %>
                        </th>
                        <td><%=vals[1]%> <%= tc.getCurrency() %>
                        </td>
                    </tr>
                    <tr class="per_tld_email" <%= PER_TLD_EMAIL_SELECTION.equals(emailSelection) ? "" : "style='display: none;'"%>>
                        <th><%= UI.tr(client, "credit_reminder_email_label", false) %>
                        </th>
                        <td>
                            <input type="text" name="<%= tld %>_email" value="<%= notificationConfig.getEmail() != null ? notificationConfig.getEmail() : "" %>">
                        </td>
                    </tr>
                    <tr>
                        <th><%= UI.tr(client, "credit_reminder_threshold_label", false) %>
                        </th>
                        <td>
                            <%= UI.tr(client, "credit_reminder_threshold_hint") %><br/>
                            <input type="text" name="<%= tld %>_threshold" value="<%= notificationConfig.getThreshold() != null ? notificationConfig.getThreshold() : "" %>">
                        </td>
                    </tr>
                    <tr>
                        <th><%= UI.tr(client, "credit_reminder_frequency_label", false) %>
                        </th>
                        <td>
                            <%= UI.tr(client, "credit_reminder_frequency_hint") %><br/>
                            <select name="<%= tld %>_frequency">
                                 <option value="DISABLED" >Disabled</option>
                                 <option value="DAILY" selected>Daily</option>
                            </select>
                        </td>
                    </tr>
                </table>
            </td>
        </tr>
        <%
            }
            if (tldToBalance.keySet().size() == 0) {
        %>
        <tr>
            <th colspan="2">
                <%= UI.tr(client, "credit_reminder_no_tlds", false) %>
            </th>
        </tr>
        <%
            }
        %>
    </table>
    <%
        if (tldToBalance.keySet().size() > 0) {
    %>

    <table style="width:600px;border-bottom-style:solid;margin-bottom:25px;padding-bottom:25px;border-width:1px;">
        <tr>
            <td colspan="2">
                <input type="submit" value="<%= UI.tr(client, "credit_reminder_save_button") %>" />
            </td>
        </tr>
    </table>
    <%
        }
    %>
</form>


<%
    request.setAttribute("menu", new ClientMenu(upClient, login, request.getContextPath()));
%>
<jsp:include page="/footer.jsp"/>

<%
    } finally {
        JDBCUtil.safeClose(dbc);
    }
%>
