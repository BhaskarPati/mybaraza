import javax.swing.JFrame;
import javax.swing.JApplet;
import javax.swing.UIManager;

public class tvtoap extends JApplet {

	public void init() {		// Run an applet	
		try {
			UIManager.setLookAndFeel("com.birosoft.liquid.LiquidLookAndFeel");
        } catch (Exception e) {
        	System.out.println("Error Loading the look");
            System.out.println(e);
        }

		viewer view = new viewer();
		getContentPane().add(view.panel);
	}

	public static void main(String[] args) {
		try {
			UIManager.setLookAndFeel("com.birosoft.liquid.LiquidLookAndFeel");
        } catch (Exception e) {
        	System.out.println("Error Loading the look");
            System.out.println(e);
        }

		JFrame frame = new JFrame("TravCom To Pastel");
        frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);

		viewer view = new viewer();
		frame.getContentPane().add(view.panel);

		frame.setSize(700, 600);
		frame.setVisible(true);
	}
}
