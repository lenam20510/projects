package com.training.usingintent;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import android.util.Log;
import android.view.Menu;
import android.view.MenuItem;
import android.view.View;
import android.widget.Toast;

public class UsingIntentActivity extends Activity {

    int request_code = 1;
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.main);
    }

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        // Inflate the menu; this adds items to the action bar if it is present.
        getMenuInflater().inflate(R.menu.using_intent, menu);
        return true;
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        // Handle action bar item clicks here. The action bar will
        // automatically handle clicks on the Home/Up button, so long
        // as you specify a parent activity in AndroidManifest.xml.
        int id = item.getItemId();
        if (id == R.id.action_settings) {
            return true;
        }
        return super.onOptionsItemSelected(item);
}
    
    public void onClick(View v) {
//        startActivity(new Intent("com.training.secondactivity"));
//        startActivityForResult(new Intent("com.training.secondactivity"), request_code);
        Intent i = new Intent("com.training.secondactivity");
        i.putExtra("str1", "This is a string");
        i.putExtra("age1", 45);
        
        Bundle extras = new Bundle();
        extras.putString("str2", "This is a other string");
        extras.putInt("age2", 46);
        i.putExtras(extras);
        
        startActivityForResult(i, request_code);
    }
    
    public void onActivityResult(int requestCode, int resultCode, Intent data) {
        if (request_code == requestCode) {
            if (resultCode == RESULT_OK) {
                Log.d("UsingIntent", "Integer.toString =" + Integer.toString(data.getIntExtra("age3", 0)));
//                Toast.makeText(this, data.getData().toString(), Toast.LENGTH_SHORT).show();
                Toast.makeText(this, Integer.toString(data.getIntExtra("age3", 0)), Toast.LENGTH_SHORT).show();
                Toast.makeText(this, data.getData().toString(), Toast.LENGTH_SHORT).show();
            }
        }
    }
}
