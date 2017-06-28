/* Formatted on 2010/08/21 13:07 (Formatter Plus v4.8.8) */
PACKAGE gen_gl
IS
   data_buff   VARCHAR2 (1000);
-- employer_pin      char(11);
   yr          CHAR (4);
   mmonth      CHAR (2);
   psummary    VARCHAR2 (500);

   TYPE gldata IS RECORD (
      pfno            NUMBER (10),
      NAME            VARCHAR2 (60),
      period          VARCHAR2 (10),
      sun_ac_code     CHAR (17),
      account_name    VARCHAR2 (50),
      debit_amount    NUMBER (18, 2),
      credit_amount   NUMBER (18, 2),
      MONTH           VARCHAR2 (8)
   );

   pgl         gldata;

   CURSOR c_gl (pmonth CHAR)
   IS
	SELECT   m.pfno, m.NAME, m.period, m.dr_cr, m.gl_code, m.account_name,
         SUM (debit_amount) debit_amount, SUM (credit_amount) credit_amount
    FROM (SELECT h.pfno, get_name (h.pfno) NAME, h.MONTH period, g.dr_cr,
                 a.gl_account gl_code, a.description account_name,
                 amount debit_amount, NULL credit_amount
            FROM emp_allowances_hist h, glmap g, gl_accounts a
           WHERE h.allowance_code = g.pay_code
             AND g.gl_code = a.gl_account
             AND h.MONTH = pmonth
          UNION ALL
          SELECT h.pfno, get_name (h.pfno), h.MONTH period, g.dr_cr,
                 a.gl_account gl_code, a.description account_name,
                 NULL debit_amount, repayment credit_amount
            FROM emp_loans_hist h, glmap g, gl_accounts a
           WHERE h.loan_code = g.pay_code
             AND g.gl_code = a.gl_account
             AND h.MONTH = pmonth
          UNION ALL
          SELECT h.pfno, get_name (h.pfno), h.MONTH period, g.dr_cr,
                 a.gl_account gl_code, a.description account_name,
                 NULL debit_amount, instalment credit_amount
            FROM ncd_hist h, glmap g, gl_accounts a
           WHERE h.deduction_code = g.pay_code
             AND g.gl_code = a.gl_account
             AND h.MONTH = pmonth
          UNION ALL
          SELECT h.pfno, get_name (h.pfno), h.MONTH period, g.dr_cr,
                 a.gl_account gl_code, a.description account_name,
                 NULL debit_amount, amount credit_amount
            FROM contributions_hist h, glmap g, gl_accounts a
           WHERE h.contribution_code = g.pay_code
             AND g.gl_code = a.gl_account
             AND h.MONTH = pmonth
          UNION ALL
          SELECT h.pfno, get_name (h.pfno), h.MONTH period, g.dr_cr,
                 a.gl_account gl_code, a.description account_name,
                 NULL debit_amount, h.amount credit_amount
            FROM pension_funds h, glmap g, gl_accounts a
           WHERE g.pay_code = h.pension_code
             AND g.gl_code = a.gl_account
             AND h.MONTH = pmonth
          UNION ALL
          SELECT h.pfno, get_name (h.pfno), h.MONTH period, 'C' dr_cr,
                 800630 gl_code, 'LOAN INTEREST' account_name,
                 NULL debit_amount, h.loan_interest credit_amount
            FROM monthly_summary h
           WHERE h.MONTH = pmonth
          UNION ALL
          SELECT h.pfno, get_name (h.pfno), h.MONTH period, g.dr_cr,
                 a.gl_account gl_code, a.description account_name,
                 NULL debit_amount, h.nhif credit_amount
            FROM monthly_summary h, glmap g, gl_accounts a
           WHERE g.pay_code = 902
             AND g.gl_code = a.gl_account
             AND h.MONTH = pmonth
          UNION ALL
          SELECT h.pfno, get_name (h.pfno), h.MONTH period, g.dr_cr,
                 a.gl_account gl_code, a.description account_name,
                 NULL debit_amount, h.payee credit_amount
            FROM monthly_summary h, glmap g, gl_accounts a
           WHERE g.pay_code = 901
             AND g.gl_code = a.gl_account
             AND h.MONTH = pmonth
          UNION ALL
          SELECT h.pfno, get_name (h.pfno), h.MONTH period, g.dr_cr,
                 a.gl_account gl_code, a.description account_name,
                 h.basic_sal debit_amount, NULL credit_amount
            FROM monthly_summary h, glmap g, gl_accounts a
           WHERE g.pay_code = 900
             AND g.gl_code = a.gl_account
             AND h.MONTH = pmonth
          UNION ALL
          SELECT h.pfno, get_name (h.pfno), h.MONTH period, g.dr_cr,
                 a.gl_account gl_code, a.description account_name,
                 NULL debit_amount, h.net_pay credit_amount
            FROM monthly_summary h, glmap g, gl_accounts a
           WHERE g.pay_code = 904
             AND g.gl_code = a.gl_account
             AND h.MONTH = pmonth) m
	GROUP BY m.pfno, m.NAME, m.period, m.dr_cr, m.gl_code, m.account_name
	ORDER BY 1, 4 DESC, 5;

--)where period=pmonth;
   PROCEDURE generate_gl (pmonth VARCHAR2);

END;


/* Formatted on 2010/08/23 08:44 (Formatter Plus v4.8.8) */
PACKAGE BODY gen_gl
IS
   fact   NUMBER := 1;

   PROCEDURE generate_gl (pmonth VARCHAR2)
   IS
      chrg_pay   NUMBER := 0;
      tx_chrgd   NUMBER := 0;
      currn      NUMBER := 0;
   BEGIN
      fact := 1;

      DELETE FROM imis_perpay_gl
            WHERE MONTH = pmonth;

      FOR i IN c_gl (pmonth)
      LOOP
         pgl.pfno := i.pfno;
         pgl.NAME := i.NAME;
         pgl.period := INITCAP (SUBSTR (i.period, 1, 3));
         pgl.sun_ac_code := i.gl_code;
         pgl.account_name := i.account_name;
         pgl.debit_amount := i.debit_amount;
         pgl.credit_amount := i.credit_amount;
         pgl.MONTH := i.period;

--Now insert into the said table
         INSERT INTO imis_perpay_gl
                     (pfno, NAME, period, sun_ac_code,
                      account_name, debit_amount, credit_amount,
                      MONTH
                     )
              VALUES (pgl.pfno, pgl.NAME, pgl.period, pgl.sun_ac_code,
                      pgl.account_name, pgl.debit_amount, pgl.credit_amount,
                      pgl.MONTH
                     );

         :msg := 'PFNO->' || pgl.pfno || ' generated...';
         currn := currn + 1;
         SYNCHRONIZE;
      END LOOP;

      :msg := 'Finished with ' || currn || ' records inserted to database.';
   EXCEPTION
      WHEN OTHERS
      THEN
         show_error_fail (SQLERRM);
   END;
END;

