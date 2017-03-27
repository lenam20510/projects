package com.example.dialog;

import android.app.Activity;
import android.app.AlertDialog;
import android.app.AlertDialog.Builder;
import android.app.Dialog;
import android.content.DialogInterface;
import android.os.Bundle;
import android.view.Menu;
import android.view.MenuItem;
import android.view.View;
import android.widget.Toast;

public class MainActivity extends Activity {

    CharSequence[] items = {"Google", "Apple", "Microsoft"};
    boolean[] itemsChecked = new boolean[items.length];
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
    }

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        // Inflate the menu; this adds items to the action bar if it is present.
        getMenuInflater().inflate(R.menu.main, menu);
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
    
    @Override
    protected Dialog onCreateDialog(int id) {
        // TODO Auto-generated method stub
        switch (id) {
        case 0:
            Builder builder = new AlertDialog.Builder(this);
            builder.setIcon(R.drawable.ic_launcher);
            builder.setTitle("This is a dialog with some simple text...");
            builder.setPositiveButton("OK",
                new DialogInterface.OnClickListener() {
                    public void onClick(DialogInterface dialog, int whichButton) {
                    Toast.makeText(getBaseContext(), "OK clicked!", Toast.LENGTH_SHORT).show();
                    }
                }
            );
            builder.setNegativeButton("Cancel", 
                new DialogInterface.OnClickListener() {
                    public void onClick(DialogInterface dialog, int whichButton) {
                    Toast.makeText(getBaseContext(), "Cancel clicked!", Toast.LENGTH_SHORT).show();
                    }
                }
            );
            builder.setMultiChoiceItems(items, itemsChecked, 
                    new DialogInterface.OnMultiChoiceClickListener() {
                        @Override
                        public void onClick(DialogInterface dialog, int which, boolean isChecked) {
                            Toast.makeText(getBaseContext(), items[which] + (isChecked ? " checked!" : " unchecked!"),
                                    Toast.LENGTH_LONG).show();
                        }
                    }
            );
            return builder.create();
        }
        return null;
    }
    
    public void onClick(View v) {
        
        showDialog(0);
    }
}
