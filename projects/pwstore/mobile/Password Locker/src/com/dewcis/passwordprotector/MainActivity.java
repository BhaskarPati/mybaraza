package com.dewcis.passwordprotector;

import java.io.File;

import org.holoeverywhere.app.Activity;
import org.holoeverywhere.preference.SharedPreferences;
import org.holoeverywhere.widget.Button;
import org.holoeverywhere.widget.EditText;

import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.os.Environment;
import android.support.v7.app.ActionBar;
import android.text.TextUtils;
import android.util.Log;
import android.view.Menu;
import android.view.View;
import android.view.View.OnClickListener;
import android.widget.ImageView;

public class MainActivity extends Activity {
	ActionBar actionBar;
	Button btnOpen;
	EditText txtPassword;
	ImageView dewcisLogo;
	String tag = BpwApplication.tag;
	@Override
	protected void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		setContentView(R.layout.activity_main);
		
		actionBar = getSupportActionBar();
		actionBar.setTitle(R.string.app_name);
		
		btnOpen = (Button) findViewById(R.id.btnOpen);
		txtPassword = (EditText) findViewById(R.id.txtPassword);
		dewcisLogo = (ImageView)findViewById(R.id.dewcisLogo);
		
		btnOpen.setOnClickListener(new OnClickListener() {
			
			@Override
			public void onClick(View v) {
				String pass = txtPassword.getText().toString();
				
				if(TextUtils.isEmpty(pass) || pass.length()<4){
					txtPassword.setError("Password Must Be More Than 4");
				}else{
					String passwdStr = new String(pass);
					
					SharedPreferences prefs = (SharedPreferences) 
												getApplicationContext()
												.getSharedPreferences(BpwApplication.PREF_NAME, BpwApplication.PRIVATE_MODE);
					String lastpass = prefs.getString(BpwApplication.KEY_PREV_PASS,BpwApplication.defaultPass);
					
					if(pass.equals(lastpass)){
						BDesEncrypter encrypter = new BDesEncrypter(passwdStr);
						String data = encrypter.decrypt(Environment.getExternalStorageDirectory()
														+ File.separator
														+ BpwApplication.appFolderName
														+ File.separator
														+ BpwApplication.KEY_FILE_NAME, true).toString();
						Log.i(tag, "DECRYPTED TEXT : " + data);					
						
						Intent i = new Intent(getSupportActionBarContext(), ViewPassActivity.class);					
						i.putExtra(BpwApplication.DECRYPT_PASSWORD, passwdStr);
						i.putExtra(BpwApplication.DECRYPTED_TEXT, data);
						startActivity(i);					
						MainActivity.this.finish();
					}else{
						String still_init_pass = "";
						if(lastpass.equals(BpwApplication.defaultPass))
							still_init_pass = "You Still Havent Changed Initial Password. : "+BpwApplication.defaultPass;
						txtPassword.setError("Invalid Password." + "\n" + still_init_pass);
					}
					
				}
				
			}
		});
		
		
		dewcisLogo.setOnClickListener(new View.OnClickListener(){
		    public void onClick(View v){
		        Intent intent = new Intent();
		        intent.setAction(Intent.ACTION_VIEW);
		        intent.addCategory(Intent.CATEGORY_BROWSABLE);
		        intent.setData(Uri.parse(getResources().getString(R.string.dewcis_url)));
		        startActivity(intent);
		    }
		});
	
	}
	

	@Override
	public boolean onCreateOptionsMenu(Menu menu) {
		// Inflate the menu; this adds items to the action bar if it is present.
		getMenuInflater().inflate(R.menu.main, menu);
		return true;
	}
}
