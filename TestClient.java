import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import android.os.Handler;
import android.os.ResultReceiver;
import android.util.Log;

public class TestClient extends Activity {
    private static final String TAG = "TestClient";
    
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        
        // Crear ResultReceiver para capturar el resultado
        ResultReceiver resultReceiver = new ResultReceiver(new Handler()) {
            @Override
            protected void onReceiveResult(int resultCode, Bundle resultData) {
                Log.d(TAG, "Resultado recibido - Código: " + resultCode);
                if (resultData != null) {
                    String jsonResult = resultData.getString("json_result");
                    Log.d(TAG, "JSON Result: " + jsonResult);
                    
                    String errorMessage = resultData.getString("error_message");
                    if (errorMessage != null) {
                        Log.e(TAG, "Error: " + errorMessage);
                    }
                }
            }
        };
        
        // Crear Intent para invocar el servicio INE
        Intent serviceIntent = new Intent();
        serviceIntent.setClassName("mx.d3c.dev.atom_ocr_ai_m_v3", "mx.d3c.dev.atom_ocr_ai_m_v3.IneServiceActivity");
        serviceIntent.putExtra("image_path", "/sdcard/Download/test_credencial.jpg");
        serviceIntent.putExtra("side", "frontal");
        serviceIntent.putExtra("result_receiver", resultReceiver);
        
        // Iniciar el servicio
        startActivity(serviceIntent);
        Log.d(TAG, "Servicio INE invocado con imagen: /sdcard/Download/test_credencial.jpg");
    }
}