import java.io.*;

public class fileMigrate {

	public static void main(String[] args) {

		String path = "jfl";
		File folder = new File(path);              
		File[] listOfFiles = folder.listFiles();

		for(File file : listOfFiles) {
			if (file.isFile()) {
				String fileName = file.getName();
				fileName = fileName.replace(" ", "").toUpperCase();
				
				String fileYear = fileName.substring(11, 13);
				String lawyerNumber = fileName.substring(0, 13);
								
				if(Integer.valueOf(fileYear).intValue()>50) fileYear = "19" + fileYear;
				else fileYear = "20" + fileYear;

				System.out.println("Processing File : " + fileName + " for year : " + fileYear);
				
				
				File sd1 = new File(path, fileYear);
				sd1.mkdir();

				File sd2 = new File(sd1.getAbsolutePath(), lawyerNumber);
				sd2.mkdir();
				
				File sd3 = new File(sd2.getAbsolutePath(), fileYear);
				sd3.mkdir();
				
				File newFile = new File(sd3.getAbsolutePath(), fileName);
				
				file.renameTo(newFile);

			}     
		}
	}
}


