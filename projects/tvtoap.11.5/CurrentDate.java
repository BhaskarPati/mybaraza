import java.util.*;

public class CurrentDate{
  public static void main(String[] args){
    Calendar cal = new GregorianCalendar();
    int month = cal.get(Calendar.MONTH);
    int year = cal.get(Calendar.YEAR);
    int day = cal.get(Calendar.DAY_OF_MONTH);
    System.out.println("Current date : " + day + "/" + (month + 1) + "/" + year);
  }
}