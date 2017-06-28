<%@ page import="cx.cocca.registry.Client"%>
<%@ page import="java.sql.Connection"%>
<%@ page import="java.math.BigDecimal"%>
<%@ page import="java.util.ArrayList"%>
<%@ page import="java.sql.SQLException"%>
<%@ page import="cx.cocca.utils.HTMLFormat"%>
<%@ page import="java.util.HashMap"%>
<%@ page import="cx.cocca.registry.payment.CreditCard"%>
<%@ page import="dewcis.payments.MakePayment"%>
<%@ page import="java.text.SimpleDateFormat"%>
<%@ page import="java.util.Date"%>
<%@ page import="java.text.ParseException"%>
<%@ page import="cx.cocca.registry.payment.PaymentException"%>
<%@ page import="cx.cocca.utils.UI" %>
<%@ page import="cx.cocca.registry.TldCurrency" %>
<%
    Client client = (Client) request.getUserPrincipal();
    ArrayList<String> errors = new ArrayList<String>();
    String roid = request.getParameter("roid");
    String action = request.getParameter("action");
    String type = request.getParameter("type");
    String amount = request.getParameter("amount");
    String note = request.getParameter("note");
    Client upClient;

    Connection dbc = client.getConnection();

    try {
        upClient = new Client(roid, dbc);
        if (!upClient.isValid())
            throw new ServletException(UI.tr(client, "client_credit_save_client_invalid", false));

        //Check permissions
        if ("adjust".equals(action) || "limit".equals(action)) {
            //Do nothing here as it will be checked on a per TLD basis later
        } else if ("payment".equals(action)) {
            //TODO what should be checked?????
        } else {
            throw new ServletException(UI.tr(client, "client_credit_save_reach", false));
        }

        if ("limit".equals(action)) {
            HashMap<String, BigDecimal> tldToLimit = new HashMap<String, BigDecimal>();
            HashMap<String, String> tldToCurrency = new HashMap<String, String>();
            HashMap<String, Boolean> tldToAllow = new HashMap<String, Boolean>();
            for (Object k : request.getParameterMap().keySet()) {
                String key = (String) k;
                if (key.endsWith("_creditLimit")) {
                    try {
                        BigDecimal l = new BigDecimal(Double.parseDouble(request.getParameter((String) k)));
                        String tld = key.replaceAll("_creditLimit", "");
                        String currency = normalize(request.getParameter(tld + "_currency"));
                        String allow_purchase = normalize(request.getParameter(tld + "_allow"));
                        if (!client.findWritableTlds().contains(tld)) {
                            errors.add(UI.trformatted(client, "client_credit_save_tld_limit_denied_template", tld, false));
                            continue;
                        }
                        if (allow_purchase != null)
                            tldToAllow.put(tld,"yes".equalsIgnoreCase(allow_purchase));
                        if (currency != null)
                            tldToCurrency.put(tld, currency);
                        tldToLimit.put(tld, l);

                        // Set the tax values
                        TldCurrency c = upClient.getTldCurrency(tld);
                        String tax = request.getParameter(tld + "_tax");
                        if (tax != null && tax.length() > 0) {
                            c.setTax(new BigDecimal(tax));
                            c.setTaxLabel(request.getParameter(tld + "_tax_label"));
                        } else {
                            c.setTax(BigDecimal.ZERO);
                            c.setTaxLabel(null);
                        }

                    } catch (Exception e) {
                        errors.add(UI.trformatted(client, "client_credit_save_bad_tld_limit_template", key.replaceAll("_creditLimit", "") , false));
                    }
                }
            }
            for (String limitTld : tldToLimit.keySet()){
                BigDecimal limit = tldToLimit.get(limitTld);
                if (limit != null)
                    upClient.setCreditLimit(limitTld,limit);
            }

            for (String t : tldToCurrency.keySet()) {
                upClient.getTldCurrency(t).setCurrency(tldToCurrency.get(t));
            }

            for (String t : tldToAllow.keySet()) {
                upClient.getTldCurrency(t).setAllowPurchase(tldToAllow.get(t));
            }
        }
        if ("adjust".equals(action)) {
            int transactionType = 0;
            BigDecimal amt = null;
            String tld = normalize(request.getParameter("tld"));

            if (!client.findWritableTlds().contains(tld)) {
                errors.add(UI.trformatted(client, "client_credit_save_tld_adjust_denied_template", tld, false));
            } else {
                try {
                    amt = new BigDecimal(Double.parseDouble(amount));
                } catch (NumberFormatException nfe) {
                    errors.add(UI.tr(client, "client_credit_save_adjust_bad_number", false));
                }
            }

            if (errors.size() == 0) {
                try {
                    upClient.adjustCredit(amt, transactionType, tld, HTMLFormat.escape(note), dbc);
                } catch (SQLException e) {
                    e.printStackTrace(System.err);
                    errors.add(UI.tr(client, "client_credit_save_db_err", false));
                }
            }
        }

        HashMap<Integer,Integer> creditTransactionIds = null;
        if ("payment".equals(action)) {
            HashMap<String, BigDecimal> tldToPayment = new HashMap<String, BigDecimal>();
            for (Object k : request.getParameterMap().keySet()) {
                String key = (String) k;
                if (key.endsWith("_amount")) {
                    try {
                        if (request.getParameter(key).length() == 0) {
                            continue;
                        }
                        BigDecimal l = new BigDecimal(Double.parseDouble(request.getParameter(key).replaceAll(",", "")));
                        switch (l.compareTo(BigDecimal.ZERO)) {
                            case-1:
                                throw new Exception();
                            case 0:
                                break;
                            case 1:
                                if (!upClient.getTldCurrency(key.replaceAll("_amount","")).allowPurchase()){
                                    errors.add(UI.trformatted(client, "client_credit_save_tld_no_buy_template", key.replaceAll("_amount",""), false));
                                    break;
                                }
                                if (l.compareTo(BigDecimal.ONE) > -1)
                                    tldToPayment.put(key.replaceAll("_amount", ""), l);
                                else
                                    throw new Exception();
                                break;
                        }
                    } catch (Exception e) {                        
                        errors.add(UI.trformatted(client, "client_credit_save_tld_min_pay_template", key.replaceAll("_amount", "") , false));
                    }
                }
            }

            String desc = normalize(request.getParameter("description"));
            String number = normalize(request.getParameter("cct_number"));
            String cvc = normalize(request.getParameter("cct_cvc"));
            String name = normalize(request.getParameter("cct_name"));
            CreditCard.cctype ctype = CreditCard.cctype.Unknown;
            if ("VISA".equals(request.getParameter("cct_type")))
                ctype = CreditCard.cctype.VISA;
            else if ("MasterCard".equals(request.getParameter("cct_type")))
                ctype = CreditCard.cctype.MasterCard;

            SimpleDateFormat sdf = new SimpleDateFormat("MMyyyy");

            int month, year;
            String mnth = null, yr = null;
            try {
                month = Integer.parseInt(request.getParameter("cct_expiry_month"));
                if (month < 1 || month > 12)
                    throw new Exception();
                mnth = normalize(request.getParameter("cct_expiry_month"));
            } catch (Exception e) {
                errors.add(UI.tr(client, "client_credit_save_no_expiry_month", false));
            }

            try {
                year = Integer.parseInt(request.getParameter("cct_expiry_year"));
                if (year > 99)
                    throw new Exception();
                yr = normalize(request.getParameter("cct_expiry_year"));
            } catch (Exception e) {
                errors.add(UI.tr(client, "client_credit_save_no_expiry_year", false));
            }

            Date expiry = null;
            if (mnth != null && yr != null) {
                try {
                    expiry = sdf.parse(mnth + 20 + yr);
                } catch (ParseException e) {
                    errors.add(UI.tr(client, "client_credit_save_bad_expiry", false));
                }
            }

                       
            CreditCard cc = new CreditCard(ctype, name, number, expiry);
            cc.setCvc(cvc);
            String ip = request.getRemoteAddr();

			System.out.println("Transaction Type : " + request.getParameter("cct_type"));

            if (errors.size() == 0) {
                try {
					if(request.getParameter("cct_type").equals("KENICPAY")) {
						MakePayment mp = new MakePayment(name, number, expiry, cvc, tldToPayment);
						creditTransactionIds = mp.updatePayments(dbc, roid, ip, desc);
					} else creditTransactionIds = upClient.purchaseCredit(dbc, tldToPayment, cc, ip, desc);
                } catch (PaymentException e) {
                    e.printStackTrace(System.err);
                    errors.add(UI.tr(client, "client_credit_save_bad_process", false));
                } catch (SQLException e) {
                    e.printStackTrace(System.err);
                    errors.add(UI.tr(client, "client_credit_save_db_err", false));
                }
            }
        }

        if (errors.size() == 0) {
            if ("limit".equals(action)) {
                try {
                    upClient.save(dbc);
                } catch (SQLException e) {
                    e.printStackTrace(System.err);
                    errors.add(UI.tr(client, "client_credit_save_db_err", false));
                }
            }
        }
        if (errors.size() > 0) {
            String msg = "";
            request.setAttribute("errors", errors);
            StringBuffer url = new StringBuffer("credit_adjust.jsp");
            url.append("?roid=" + roid);
            url.append("&action=" + action);
            if ("adjust".equals(action)) {
                url.append("&type=" + type);
                url.append("&amount=" + amount);
                url.append("&note=" + note);
                msg = UI.tr(client, "client_credit_save_err_adjustment", false);

            } else if ("payment".equals(action)) {
                url = new StringBuffer("credit_purchase_step_1.jsp");
                url.append("?roid=" + roid);
                msg = UI.tr(client, "client_credit_save_err_pay", false);
            }
            redirect(request, response, url.toString(), msg);
        } else {
            String msg = "";
            StringBuffer url = new StringBuffer("credit_adjust.jsp?roid=" + roid);
            if ("adjust".equals(action)) {
                msg = UI.tr(client, "client_credit_save_success_adjust", false);
            } else if ("limit".equals(action)) {
                msg = UI.tr(client, "client_credit_save_success_limit", false); 
            } else if ("payment".equals(action)) {
                msg = null;
                url = new StringBuffer("payment_receipt.jsp?roid=" + upClient.getRoid());
                for (int i : creditTransactionIds.keySet()){
                    String p = i+"";
                    if (creditTransactionIds.get(i) != null)
                        p += ("L"+creditTransactionIds.get(i));
                    url.append("&cct_id=" + p);
                }
            }
			System.out.println(url.toString());
            redirect(request, response, url.toString(), msg);
        }

    } finally {
        if (dbc != null) dbc.close();
    }


%>

<%!

    public void redirect(HttpServletRequest req, HttpServletResponse res, String url, String msg) throws Exception {
        req.setAttribute("res_msg", msg);
        req.getRequestDispatcher(url).forward(req, res);
    }

    public String normalize(String in){
        if (in == null) return null;
        in = in.trim();
        if (in.length() == 0) return null;
        return in;
    }
%>
