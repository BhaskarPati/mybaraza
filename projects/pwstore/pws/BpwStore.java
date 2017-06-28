/**
 * @author      Dennis W. Gichangi <dennis@openbaraza.org>
 * @version     2011.0329
 * @since       1.6
 * website		www.openbaraza.org
 * The contents of this file are subject to the GNU Lesser General Public License
 * Version 3.0 ; you may use this file in compliance with the License.
 */
package pws;

import java.io.Console;
import java.lang.Math;

import java.awt.Color;
import java.awt.BorderLayout;
import java.awt.Font;
import java.awt.event.ActionListener;
import java.awt.event.ActionEvent;

import javax.swing.JFrame;
import javax.swing.JPanel;
import javax.swing.JScrollPane;
import javax.swing.JTextArea;
import javax.swing.JButton;
import javax.swing.JPasswordField;
import javax.swing.JTextField;
import javax.swing.JLabel;
import javax.swing.JSpinner;
import javax.swing.SpinnerModel;
import javax.swing.SpinnerNumberModel;
import javax.swing.JOptionPane;
import javax.swing.UIManager;
import javax.swing.text.Highlighter;
import javax.swing.text.DefaultHighlighter;
import javax.swing.text.BadLocationException;

public class BpwStore implements ActionListener {

	JTextArea ta;
	JTextField tf;
	JTextField newTf;
	JPasswordField pwf;
	JSpinner spinner;
	Highlighter taHi;

	int lastSearch = 0;

	JPanel btPanel;
	JPanel taPanel;

	public static void main(String args[]) {
		if(args.length < 1) { BpwStore pwStore = new BpwStore(); }
		else if(args.length < 2) { showPasswordFile(null); }
		else if(args.length < 3) { showPasswordFile(args[1]); }
	}

	public static void showPasswordFile(String searchStr) {
		Console console = System.console();

		System.out.print("Enter password : ");
		char[] passwordChars = console.readPassword();
        String passwordString = new String(passwordChars);

		// Create encrypter/decrypter class
		BDesEncrypter encrypter = new BDesEncrypter(passwordString);

		// Encrypt
		int i = 0;
		String passwdData = encrypter.decrypt("store.cph", true);
		if(searchStr == null) {
			System.out.println(passwdData);
		} else {
			String passwdLines[] = passwdData.split("\n");
			for(String passwdLine : passwdLines) {
				if(passwdLine.toLowerCase().contains(searchStr.toLowerCase())) i = 5;
			
				if(i > 0) {
					System.out.println(passwdLine);
					i--;
				}
			}
		}
		System.out.println("\n");
	}

	public BpwStore() {
		try {
			UIManager.setLookAndFeel(UIManager.getSystemLookAndFeelClassName());
		} catch (Exception ex) {
			System.out.println("Error Loading the look : " + ex);
		}

		ta = new JTextArea();
		taHi = ta.getHighlighter();
		ta.setTabSize(4);
		ta.setFont(new Font("Monospaced", Font.PLAIN, 12));
		JScrollPane scrollPane = new JScrollPane(ta);

		JLabel lbPasswd = new JLabel("Password : ");
		pwf = new JPasswordField(10);
		pwf.setActionCommand("Open");
		pwf.addActionListener(this);
		JButton btSave = new JButton("Save");
		btSave.addActionListener(this);
		JLabel lbSearch = new JLabel("Search");
		tf = new JTextField(10);
		tf.setActionCommand("Search");
		tf.addActionListener(this);

		newTf = new JTextField(10);
		newTf.setActionCommand("new");
		newTf.addActionListener(this);

		SpinnerModel spinnerModel = new SpinnerNumberModel(12, 5, 32, 1);
		spinner = new JSpinner(spinnerModel);

		btPanel = new JPanel();
		taPanel = new JPanel(new BorderLayout());
		taPanel.add(scrollPane, BorderLayout.CENTER);

		btPanel.add(newTf);
		btPanel.add(spinner);
		btPanel.add(btSave);
		btPanel.add(lbPasswd);
		btPanel.add(pwf);
		btPanel.add(lbSearch);
		btPanel.add(tf);

		JFrame frame = new JFrame("Dennis Password Locker");
		frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
		frame.getContentPane().add(btPanel, BorderLayout.PAGE_START);
		frame.getContentPane().add(taPanel, BorderLayout.CENTER);
		frame.setLocation(75, 25);
		frame.setSize(800, 550);
		frame.setVisible(true);

		pwf.grabFocus();
	}

	public void actionPerformed(ActionEvent ae) {
		String cmd = ae.getActionCommand();
		if(cmd.equals("Open")) { 
			openFile();
		} else if(cmd.equals("Save")) {
			saveFile();
		} else if(cmd.equals("Search")) {
			search();
		} else if(cmd.equals("new")) {
			newPassword();
		}
	}

	public void saveFile() {
		char[] passwd = pwf.getPassword();
		String fileStr = ta.getText();

		int n = JOptionPane.showConfirmDialog(taPanel, "Are you sure you want to save?", "SURE YOU WANT TO SAVE", JOptionPane.YES_NO_OPTION);

		if(n == 1) {
			System.out.println("Abort saving");
		} else if(passwd.length < 4) {
			JOptionPane.showMessageDialog(taPanel, "Password should be more than 4 characters long.");
		} else if(fileStr.length() < 1) {
			JOptionPane.showMessageDialog(taPanel, "You need to add information to save");
		} else {
			String passwdStr = new String(passwd);

			// Create encrypter/decrypter class
			BDesEncrypter encrypter = new BDesEncrypter(passwdStr);

			// Encrypt
			encrypter.encrypt(fileStr, "store.cph", true);
		}
	}

	public void openFile() {
		char[] passwd = pwf.getPassword();
		String fileStr = ta.getText();
		if(passwd.length < 4) {
			JOptionPane.showMessageDialog(taPanel, "Password should be more than 4 characters long.");
		} else {
			String passwdStr = new String(passwd);

			// Create encrypter/decrypter class
			BDesEncrypter encrypter = new BDesEncrypter(passwdStr);

			// Encrypt
			ta.setText(encrypter.decrypt("store.cph", true));
			ta.setCaretPosition(0);
		}
	}

	public void search() {
		String fileStr = ta.getText();
		String searchStr = tf.getText();

		int pos = fileStr.toUpperCase().indexOf(searchStr.toUpperCase(), lastSearch);
		if(pos>=0) {
			lastSearch = pos + searchStr.length();
			try {
				taHi.removeAllHighlights();
				DefaultHighlighter.DefaultHighlightPainter highlightPainter = new DefaultHighlighter.DefaultHighlightPainter(Color.YELLOW);
				taHi.addHighlight(pos, pos + searchStr.length(), highlightPainter);
				
				ta.setCaretPosition(pos);
			} catch(BadLocationException ex) {
				System.out.println("Highlighter error : " + ex);
			}
		} else {
			lastSearch = 0;
		}

		System.out.println("Pos : " + pos);
	}

	public void newPassword() {
		//for(int i = 48; i < 123; i++) { }
		Integer mvs = new Integer(spinner.getValue().toString());
		String newPass = "";

		for(int i = 0; i < mvs.intValue(); i++) {
			Double dch = Math.random() * 74;
			int pch = 48 + dch.intValue();
			newPass += String.valueOf((char)pch);
		}
		newTf.setText(newPass);
	}

}
