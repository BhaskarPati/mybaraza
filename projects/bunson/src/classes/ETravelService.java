
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.logging.Logger;
import java.util.Date;

import javax.servlet.ServletContext;
import javax.servlet.ServletContextEvent;
import javax.servlet.ServletContextListener;

import org.baraza.DB.BDB;
import org.baraza.DB.BQuery;

//import ESync;


public class ETravelService implements ServletContextListener {
	private Thread t = null;
    private ServletContext context;
    
    static boolean doLog = false;
    static boolean doSysOut = false;
	static Logger log = Logger.getLogger(ETravelService.class.getName());
	@Override
	public void contextDestroyed(ServletContextEvent contextEvent) {
		// context is destroyed interrupts the thread
        t.interrupt();
		
	}

    @SuppressWarnings("deprecation")
	@Override
	public void contextInitialized(ServletContextEvent contextEvent) {
		t =  new Thread(){
            //task
            public void run(){               
                try {
                    while(true){
                    	
                        
                        ESync.sync(ESync.SUPPLIERS);
                        ESync.sync(ESync.CUSTOMER_CODES);
                        ESync.sync(ESync.CURRENCY);
                        ESync.sync(ESync.CAR_TYPES);
                        ESync.sync(ESync.LOCATIONS);
                        ESync.syncBookings();
                    
                        Thread.sleep(60000);
                    
                    }
                } catch (InterruptedException e) {}
            }            
        };
        t.start();
        context = contextEvent.getServletContext();	
	}
}
