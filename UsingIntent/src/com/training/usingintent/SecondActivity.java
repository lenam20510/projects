package com.training.usingintent;

import android.app.Activity;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.view.View;
import android.widget.EditText;
import android.widget.Toast;

public class SecondActivity extends Activity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        // TODO Auto-generated method stub
        super.onCreate(savedInstanceState);
        setContentView(R.layout.secondactivity);
        
        Toast.makeText(this, getIntent().getStringExtra("str1"), Toast.LENGTH_LONG).show();
        Toast.makeText(this, Integer.toString(getIntent().getIntExtra("age1", 0)), Toast.LENGTH_LONG).show();
        
        Bundle extras = getIntent().getExtras();
        Toast.makeText(this, extras.getString("str2"), Toast.LENGTH_LONG).show();
        Toast.makeText(this, Integer.toString(extras.getInt("age2")), Toast.LENGTH_LONG).show();
    }
    
    public void onClick(View v) {
        Intent data = new Intent();
//        EditText txt_username = (EditText) findViewById(R.id.txt_username);
//        data.setData(Uri.parse(txt_username.getText().toString()));
        data.putExtra("age3", 50);
        data.setData(Uri.parse("Something passed back to main activity"));
        
        setResult(RESULT_OK, data);
        finish();
    }
}
