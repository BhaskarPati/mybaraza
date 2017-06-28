UPDATE gl_accounts SET gl_account = '502800' WHERE gl_account = '200000';
UPDATE gl_accounts SET gl_account = '502804' WHERE gl_account = '200004';
UPDATE gl_accounts SET gl_account = '502813' WHERE gl_account = '200013';
UPDATE gl_accounts SET gl_account = '100401' WHERE gl_account = '700401';
UPDATE gl_accounts SET gl_account = '200401' WHERE gl_account = '800601';
UPDATE gl_accounts SET gl_account = '200402' WHERE gl_account = '800602';
UPDATE gl_accounts SET gl_account = '200403' WHERE gl_account = '800603';
UPDATE gl_accounts SET gl_account = '200426' WHERE gl_account = '800626';
UPDATE gl_accounts SET gl_account = '200427' WHERE gl_account = '800630';
UPDATE gl_accounts SET gl_account = '200439' WHERE gl_account = '800639';

UPDATE gl_accounts SET gl_account = '400004' WHERE gl_account = '100004';
UPDATE gl_accounts SET gl_account = '100406' WHERE gl_account = '700406';
UPDATE gl_accounts SET gl_account = '200431' WHERE gl_account = '800641';

UPDATE pay_codes SET gl_cr_acc = '502800' WHERE gl_cr_acc = '200000';
UPDATE pay_codes SET gl_cr_acc = '502804' WHERE gl_cr_acc = '200004';
UPDATE pay_codes SET gl_cr_acc = '502813' WHERE gl_cr_acc = '200013';
UPDATE pay_codes SET gl_cr_acc = '100401' WHERE gl_cr_acc = '700401';
UPDATE pay_codes SET gl_cr_acc = '200401' WHERE gl_cr_acc = '800601';
UPDATE pay_codes SET gl_cr_acc = '200402' WHERE gl_cr_acc = '800602';
UPDATE pay_codes SET gl_cr_acc = '200403' WHERE gl_cr_acc = '800603';
UPDATE pay_codes SET gl_cr_acc = '200426' WHERE gl_cr_acc = '800626';
UPDATE pay_codes SET gl_cr_acc = '200427' WHERE gl_cr_acc = '800630';
UPDATE pay_codes SET gl_cr_acc = '200439' WHERE gl_cr_acc = '800639';

UPDATE pay_codes SET gl_cr_acc = '400004' WHERE gl_cr_acc = '100004';
UPDATE pay_codes SET gl_cr_acc = '100406' WHERE gl_cr_acc = '700406';
UPDATE pay_codes SET gl_cr_acc = '200431' WHERE gl_cr_acc = '800641';

UPDATE pay_codes SET gl_dr_acc = '502800' WHERE gl_dr_acc = '200000';
UPDATE pay_codes SET gl_dr_acc = '502804' WHERE gl_dr_acc = '200004';
UPDATE pay_codes SET gl_dr_acc = '502813' WHERE gl_dr_acc = '200013';
UPDATE pay_codes SET gl_dr_acc = '100401' WHERE gl_dr_acc = '700401';
UPDATE pay_codes SET gl_dr_acc = '200401' WHERE gl_dr_acc = '800601';
UPDATE pay_codes SET gl_dr_acc = '200402' WHERE gl_dr_acc = '800602';
UPDATE pay_codes SET gl_dr_acc = '200403' WHERE gl_dr_acc = '800603';
UPDATE pay_codes SET gl_dr_acc = '200426' WHERE gl_dr_acc = '800626';
UPDATE pay_codes SET gl_dr_acc = '200427' WHERE gl_dr_acc = '800630';
UPDATE pay_codes SET gl_dr_acc = '200439' WHERE gl_dr_acc = '800639';

UPDATE pay_codes SET gl_dr_acc = '400004' WHERE gl_dr_acc = '100004';
UPDATE pay_codes SET gl_dr_acc = '100406' WHERE gl_dr_acc = '700406';
UPDATE pay_codes SET gl_dr_acc = '200431' WHERE gl_dr_acc = '800641';


INSERT INTO erpdbuser.dc_ledger (pf_number, staff_name, period_no, ledger_no,
	payroll_account, description, debit,  credit)
SELECT   m.pfno, m.NAME, m.period, m.dr_cr, m.gl_code, m.account_name,
     SUM (debit_amount) debit_amount, SUM (credit_amount) credit_amount
FROM (SELECT h.pfno, get_name (h.pfno) NAME, h.MONTH period, g.dr_cr,
             a.gl_account gl_code, a.description account_name,
             amount debit_amount, NULL credit_amount
        FROM emp_allowances_hist h, glmap g, gl_accounts a
       WHERE h.allowance_code = g.pay_code
         AND g.gl_code = a.gl_account
      UNION ALL
      SELECT h.pfno, get_name (h.pfno), h.MONTH period, g.dr_cr,
             a.gl_account gl_code, a.description account_name,
             NULL debit_amount, repayment credit_amount
        FROM emp_loans_hist h, glmap g, gl_accounts a
       WHERE h.loan_code = g.pay_code
         AND g.gl_code = a.gl_account
      UNION ALL
      SELECT h.pfno, get_name (h.pfno), h.MONTH period, g.dr_cr,
             a.gl_account gl_code, a.description account_name,
             NULL debit_amount, instalment credit_amount
        FROM ncd_hist h, glmap g, gl_accounts a
       WHERE h.deduction_code = g.pay_code
         AND g.gl_code = a.gl_account
      UNION ALL
      SELECT h.pfno, get_name (h.pfno), h.MONTH period, g.dr_cr,
             a.gl_account gl_code, a.description account_name,
             NULL debit_amount, amount credit_amount
        FROM contributions_hist h, glmap g, gl_accounts a
       WHERE h.contribution_code = g.pay_code
         AND g.gl_code = a.gl_account
      UNION ALL
      SELECT h.pfno, get_name (h.pfno), h.MONTH period, g.dr_cr,
             a.gl_account gl_code, a.description account_name,
             NULL debit_amount, h.amount credit_amount
        FROM pension_funds h, glmap g, gl_accounts a
       WHERE g.pay_code = h.pension_code
         AND g.gl_code = a.gl_account
      UNION ALL
      SELECT h.pfno, get_name (h.pfno), h.MONTH period, 'C' dr_cr,
             200427 gl_code, 'LOAN INTEREST' account_name,
             NULL debit_amount, h.loan_interest credit_amount
        FROM monthly_summary h
      UNION ALL
      SELECT h.pfno, get_name (h.pfno), h.MONTH period, g.dr_cr,
             a.gl_account gl_code, a.description account_name,
             NULL debit_amount, h.nhif credit_amount
        FROM monthly_summary h, glmap g, gl_accounts a
       WHERE g.pay_code = 902
         AND g.gl_code = a.gl_account
      UNION ALL
      SELECT h.pfno, get_name (h.pfno), h.MONTH period, g.dr_cr,
             a.gl_account gl_code, a.description account_name,
             NULL debit_amount, h.payee credit_amount
        FROM monthly_summary h, glmap g, gl_accounts a
       WHERE g.pay_code = 901
         AND g.gl_code = a.gl_account
      UNION ALL
      SELECT h.pfno, get_name (h.pfno), h.MONTH period, g.dr_cr,
             a.gl_account gl_code, a.description account_name,
             h.basic_sal debit_amount, NULL credit_amount
        FROM monthly_summary h, glmap g, gl_accounts a
       WHERE g.pay_code = 900
         AND g.gl_code = a.gl_account
      UNION ALL
      SELECT h.pfno, get_name (h.pfno), h.MONTH period, g.dr_cr,
             a.gl_account gl_code, a.description account_name,
             NULL debit_amount, h.net_pay credit_amount
        FROM monthly_summary h, glmap g, gl_accounts a
       WHERE g.pay_code = 904
         AND g.gl_code = a.gl_account) m
WHERE (m.period = 'MAR-2012') and (m.pfno = '20006')
GROUP BY m.pfno, m.NAME, m.period, m.dr_cr, m.gl_code, m.account_name
ORDER BY 1, 4 DESC, 5;

