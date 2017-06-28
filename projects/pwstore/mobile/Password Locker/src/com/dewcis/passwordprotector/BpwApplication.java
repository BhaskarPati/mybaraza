package com.dewcis.passwordprotector;

import java.io.File;
import java.io.IOException;

import org.holoeverywhere.app.Application;
import org.holoeverywhere.preference.SharedPreferences;
import org.holoeverywhere.preference.SharedPreferences.Editor;

import android.os.Environment;
import android.util.Log;

public class BpwApplication extends Application{
	public static String appFolderName = "Bpassprotect",
						 defaultPass = "password";
	
	public static String KEY_FILE_NAME = "pstore",
						 DECRYPTED_TEXT = "decrypted_text",
						 DECRYPT_PASSWORD = "password",
						 KEY_PREV_PASS= "lastpass";
	public static String tag = "Bpw";
	
	public static final String PREF_NAME = "BpassPref";
	public static int PRIVATE_MODE = 0;
	
	
	
	
	
	@Override
	 public void onCreate() {
		if(!Environment.getExternalStorageState().equals(Environment.MEDIA_MOUNTED)){
			Log.d(tag, "No SDCARD");
		}else { 
			File myAppFolder = new File(Environment.getExternalStorageDirectory()+File.separator+appFolderName);
		    
			if(!(myAppFolder.exists() && myAppFolder.isDirectory())){
				
		          myAppFolder.mkdirs();
		          Log.i(tag, "Folder created Successfully");
		          
		          File newStoreCph = new File(Environment.getExternalStorageDirectory() 
		        		  						+ File.separator
		        		  						+appFolderName
		        		  						+File.separator
		        		  						+KEY_FILE_NAME);
		        try {
					if(newStoreCph.createNewFile()){
						Log.i(tag, "File Created Successfully.");
						try {
							BDesEncrypter encrypter = new BDesEncrypter(defaultPass);

							encrypter.encrypt("Thank you for using pass protector. Please change your password.", 
									Environment.getExternalStorageDirectory()+File.separator+appFolderName+File.separator+KEY_FILE_NAME, true);
							Log.i(tag, "File Enrypted Successfully.");
							
							SharedPreferences prefs = (SharedPreferences) getApplicationContext().getSharedPreferences(PREF_NAME, PRIVATE_MODE);
							Editor editor = prefs.edit();
							
							editor.putString(KEY_PREV_PASS, defaultPass);
							editor.commit();
							
						} catch (Exception e) {
							Log.e(tag, "Error encypting File");
						}
						
					}
				} catch (IOException e) {
					Log.e(tag, "Error Creating File");
				}
		          
		      } else{
				  Log.d(tag, "Folder Already Exists");
		      }
		 }
	       super.onCreate();
	   }
	
}
