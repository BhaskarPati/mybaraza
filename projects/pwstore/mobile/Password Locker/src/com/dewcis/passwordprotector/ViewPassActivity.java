package com.dewcis.passwordprotector;

import java.io.File;
import java.util.Locale;
import java.util.Random;

import org.holoeverywhere.LayoutInflater;
import org.holoeverywhere.ThemeManager;
import org.holoeverywhere.app.Activity;
import org.holoeverywhere.app.AlertDialog;
import org.holoeverywhere.preference.SharedPreferences;
import org.holoeverywhere.preference.SharedPreferences.Editor;
import org.holoeverywhere.widget.Button;
import org.holoeverywhere.widget.EditText;
import org.holoeverywhere.widget.TextView;
import org.holoeverywhere.widget.Toast;


import android.app.SearchManager;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.os.Bundle;
import android.os.Environment;


import android.support.v4.view.MenuItemCompat;
import android.support.v7.app.ActionBar;
import android.support.v7.widget.SearchView;
import android.text.TextUtils;
import android.util.Log;
import android.view.Menu;
import android.view.MenuInflater;
import android.view.MenuItem;
import android.view.View;
import android.view.View.OnClickListener;

public class ViewPassActivity extends Activity implements SearchView.OnQueryTextListener{
	
	EditText txtSecrets, txtNewPassword;
	
	Button btnSaveNew;
	String tag = BpwApplication.tag;
	ActionBar actionBar;
	String newPassword;
	String updated_secrets, decrypted;
	SearchView searchView ;
	
	//------------dialog
	String newGenPass ;
	EditText txtPassLength;
	TextView lblGenNewpassword;
	Button btnGenerate;
	int passLength ;
	
	@Override
	protected void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		setContentView(R.layout.activity_view_pass);
		
		Bundle bundle = getIntent().getExtras();
		final String init_pass = bundle.getString(BpwApplication.DECRYPT_PASSWORD);
		decrypted = bundle.getString(BpwApplication.DECRYPTED_TEXT);
		
		actionBar = getSupportActionBar();
		actionBar.setTitle("My Secrets");
		actionBar.setDisplayHomeAsUpEnabled(true);
		actionBar.setHomeButtonEnabled(true);
		//actionBar.setSplitBackgroundDrawable();
		
		txtNewPassword = (EditText) findViewById(R.id.txtNewPassword);
		txtSecrets = (EditText) findViewById(R.id.txtSecrets);
		
		btnSaveNew = (Button) findViewById(R.id.btnSaveNew);
		
		txtSecrets.setText(decrypted);
		
		btnSaveNew.setOnClickListener(new OnClickListener() {
			
			@Override
			public void onClick(View v) {
				newPassword = txtNewPassword.getText().toString();
				updated_secrets = txtSecrets.getText().toString();
				
				if(TextUtils.isEmpty(newPassword)){
					if(init_pass.equals(BpwApplication.defaultPass)){
						Toast.makeText(getApplicationContext(), "You have to change initial password.", Toast.LENGTH_SHORT).show();
						txtNewPassword.requestFocus();
					}else{
						
						AlertDialog.Builder builder = new AlertDialog.Builder(getSupportActionBarContext());
	                    builder.setTheme(ThemeManager.LIGHT);
	                    builder.setTitle(R.string.app_name);
	                    builder.setIcon(R.drawable.ic_launcher);
	                    builder.setMessage("Save Info with old Password ? ");                    
	                    builder.setNegativeButton("No.", new DialogInterface.OnClickListener() {
							
							@Override
							public void onClick(DialogInterface dialog, int which) {
								Toast.makeText(getApplicationContext(), "Enter New Password.", Toast.LENGTH_SHORT).show();
								txtNewPassword.requestFocus();
								
							}
						});
	                    
	                    builder.setPositiveButton("Yes", new DialogInterface.OnClickListener() {
							
							@Override
							public void onClick(DialogInterface dialog, int which) {							
								saveFile( init_pass, updated_secrets);
							}
						});
	                    builder.setCancelable(false);
	                    builder.create();
	                    builder.show();
					}
				}else{
					if(newPassword.length() <= 4){
						txtNewPassword.setError("Password Must Be More Than 4 Characters");
					}else{
						saveFile( newPassword,  updated_secrets);
					}
				}
				
			}
		});
		
		
		
	}
	
	public void saveFile(final String pass, final String updated_secrets){
		final EditText txtConfirmPassword;
		Button btnConfirmCancel,btnConfirmSave;
		
		final AlertDialog.Builder builder = new AlertDialog.Builder(getSupportActionBarContext());
		
        builder.setTheme(ThemeManager.LIGHT);
        builder.setTitle(R.string.app_name);
        builder.setIcon(R.drawable.ic_launcher);
        LayoutInflater inflater = (LayoutInflater) getSystemService(Context.LAYOUT_INFLATER_SERVICE);
        View view = inflater.inflate(R.layout.confirm_pass);
        txtConfirmPassword = (EditText) view.findViewById(R.id.txtConfirmPassword);
        btnConfirmCancel = (Button) view.findViewById(R.id.btnConfirmCancel);
        btnConfirmSave = (Button) view.findViewById(R.id.btnConfirmSave);
        builder.setView(view);
        final AlertDialog alertDialog = builder.create();
        btnConfirmCancel.setOnClickListener(new OnClickListener() {
			
			@Override
			public void onClick(View arg0) {
				alertDialog.dismiss();
				
			}
		});
        btnConfirmSave.setOnClickListener(new OnClickListener() {
			
			@Override
			public void onClick(View v) {
				String c_pass = txtConfirmPassword.getText().toString();
				if(c_pass.equals(pass)){
					BDesEncrypter encrypter = new BDesEncrypter(pass);
					encrypter.encrypt(updated_secrets, 									
									  Environment.getExternalStorageDirectory()
									  +File.separator
									  +BpwApplication.appFolderName
									  +File.separator
									  +BpwApplication.KEY_FILE_NAME, true);
					Toast.makeText(getApplicationContext(), "File Saved Successfully.", Toast.LENGTH_SHORT).show();
					decrypted = updated_secrets;
					SharedPreferences prefs = (SharedPreferences) 
							getApplicationContext()
							.getSharedPreferences(BpwApplication.PREF_NAME, BpwApplication.PRIVATE_MODE);
					Editor editor = (Editor) prefs.edit();
					
					editor.putString(BpwApplication.KEY_PREV_PASS, pass);
					editor.commit();
					alertDialog.dismiss();
					Log.i(tag, "File Enrypted Successfully.");
				}else{
					//Toast.makeText(getSupportActionBarContext(), "", Toast.LENGTH_LONG).show();
					txtConfirmPassword.setError("Passwords Do not Match");
					
				}
				
			}
		});
        
        alertDialog.show();
        //builder.setCancelable(false);
        //builder.create();
        //builder.show();
		
		
		
		
	}

	@Override
	public boolean onCreateOptionsMenu(Menu menu) {
		MenuInflater inflater = getMenuInflater();
		inflater.inflate(R.menu.view_pass, menu);
		
		MenuItem searchItem = menu.findItem(R.id.action_search);
	    searchView = (SearchView) MenuItemCompat.getActionView(searchItem);
	    
	    SearchManager searchManager = (SearchManager) getSystemService(Context.SEARCH_SERVICE);
	    searchView.setSearchableInfo(searchManager.getSearchableInfo(getComponentName()));
	    searchView.setOnQueryTextListener(this);
	    
		return super.onCreateOptionsMenu(menu);
	}
	
	@Override
	public boolean onOptionsItemSelected(MenuItem item) {
		switch(item.getItemId()){
		case R.id.mnu_exit:
			if(updated_secrets != decrypted){
				Toast.makeText(getApplicationContext(), "Save File First Before Exiting.", Toast.LENGTH_LONG).show();
				
			}else{
				Toast.makeText(getApplicationContext(), "Saved And Exiting.", Toast.LENGTH_LONG).show();
				backToLogin();
			}			
		return true;
		
		case R.id.action_search:
			txtNewPassword.clearFocus();
			searchView.requestFocus();
		return true;
		case R.id.action_genpass:
			showPassGenerator();
			return true;
		
		
		default:
            return super.onOptionsItemSelected(item);
		}
	}
	
	public void backToLogin(){
		Intent i = new Intent(getSupportActionBarContext(), MainActivity.class);
		startActivity(i);
		ViewPassActivity.this.finish();
	}

	@Override
	public boolean onQueryTextSubmit(String query) {
		//Toast.makeText(this, query, Toast.LENGTH_SHORT).show();
		String searchStr = query;
		String fileStr = txtSecrets.getText().toString();
		int pos = fileStr.toUpperCase(Locale.ENGLISH).indexOf(searchStr.toUpperCase());
		
		if(pos >=0){
			txtSecrets.requestFocus();
			txtSecrets.setSelection(pos,pos+searchStr.length());
		}else{
			Toast.makeText(getApplicationContext(), "No Match Found.", Toast.LENGTH_SHORT).show();
		}
		return true;
	}

	@Override
	public boolean onQueryTextChange(String newText) {
		
		return false;
	}
	
	public String generate(int passLength){
		String characters = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz!@#$%^&*()_=+";
		Random random = new Random();
		char[] pass = new char[passLength];
		for (int i = 0; i < passLength; i++){
			pass[i] = characters.charAt(random.nextInt(characters.length()));
		}
		return String.valueOf(pass);
	}

	public void showPassGenerator(){
		AlertDialog.Builder builder = new AlertDialog.Builder(ViewPassActivity.this);
		builder.setTitle(R.string.app_name);
		builder.setIcon(R.drawable.ic_launcher);
		builder.setMessage(R.string.auto_generate_pass);
		builder.setCancelable(false);
		
		LayoutInflater inflater = (LayoutInflater) getSystemService(Context.LAYOUT_INFLATER_SERVICE);
		View dialogView = inflater.inflate(R.layout.generator_dialog);
		builder.setView(dialogView);
		
		txtPassLength =  (EditText) dialogView.findViewById(R.id.txtPassLength);
		lblGenNewpassword = (TextView) dialogView.findViewById(R.id.lblGenNewpassword);
		btnGenerate = (Button) dialogView.findViewById(R.id.btnGenerate);
		
		btnGenerate.setOnClickListener(new OnClickListener() {
			
			@Override
			public void onClick(View v) {
				String pl = txtPassLength.getText().toString();
				if(TextUtils.isEmpty(pl)){	pl = "0";}
				passLength = Integer.parseInt(pl);
				newGenPass = generate(passLength);
				if(passLength <= 4){
					txtPassLength.setError("Password Must More Than 4");
				}else{
					lblGenNewpassword.setText("Password : " + newGenPass);
					
				}
			}
		});
		
		builder.setNegativeButton("Cancel", new DialogInterface.OnClickListener() {
			
			@Override
			public void onClick(DialogInterface dialog, int which) {
				// TODO Auto-generated method stub
				
			}
		});
		builder.setPositiveButton("Use Password", new DialogInterface.OnClickListener() {
			
			@Override
			public void onClick(DialogInterface dialog, int which) {
				if(passLength <= 4){
					txtPassLength.setError("Password Must More Than 4");
				}else{
					txtNewPassword.setText(newGenPass);
					txtNewPassword.setSelection(0, passLength);
				}
			}
		});
		builder.create();
		builder.show();
	}
}
