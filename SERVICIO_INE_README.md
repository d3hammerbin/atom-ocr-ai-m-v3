# Servicio de Procesamiento INE - Guía de Integración

## Descripción

Este servicio permite a aplicaciones externas procesar credenciales INE (Instituto Nacional Electoral) mediante una Activity nativa de Android que puede ser invocada desde otras aplicaciones.

## Características

- **Procesamiento offline**: Todo el procesamiento se realiza localmente sin conexión a internet
- **Extracción de texto**: Utiliza MLKit para extraer texto de imágenes de credenciales
- **Validación automática**: Verifica que la imagen corresponda a una credencial INE válida
- **Detección de lado**: Identifica automáticamente si es el lado frontal o reverso
- **Datos estructurados**: Devuelve información procesada en formato JSON
- **ResultReceiver**: Comunicación asíncrona con la aplicación origen

## Configuración del Manifest

La Activity de servicio está configurada como exportable en el AndroidManifest.xml:

```xml
<activity
    android:name=".IneServiceActivity"
    android:exported="true"
    android:theme="@style/Theme.AtomOcrAiMV3"
    android:screenOrientation="portrait" />
```

## Invocación desde Aplicaciones Externas

### Parámetros Requeridos

- `imagePath` (String): Ruta absoluta de la imagen de la credencial INE
- `side` (String): Lado de la credencial ("frontal" o "reverso")
- `resultReceiver` (ResultReceiver): Receptor para recibir los resultados del procesamiento

### Ejemplo de Invocación en Kotlin

```kotlin
import android.content.Intent
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.ResultReceiver
import android.util.Log

class MainActivity : AppCompatActivity() {
    
    private val ineResultReceiver = object : ResultReceiver(Handler(Looper.getMainLooper())) {
        override fun onReceiveResult(resultCode: Int, resultData: Bundle?) {
            when (resultCode) {
                RESULT_OK -> {
                    val jsonResult = resultData?.getString("result")
                    Log.d("INE_SERVICE", "Procesamiento exitoso: $jsonResult")
                    // Procesar el JSON con los datos de la credencial
                    handleSuccessResult(jsonResult)
                }
                RESULT_CANCELED -> {
                    val error = resultData?.getString("error")
                    Log.e("INE_SERVICE", "Error en procesamiento: $error")
                    handleErrorResult(error)
                }
            }
        }
    }
    
    private fun invokeIneService(imagePath: String, side: String) {
        val intent = Intent().apply {
            setClassName(
                "mx.d3c.dev.atom_ocr_ai_m_v3",
                "mx.d3c.dev.atom_ocr_ai_m_v3.IneServiceActivity"
            )
            putExtra("imagePath", imagePath)
            putExtra("side", side)
            putExtra("resultReceiver", ineResultReceiver)
        }
        
        try {
            startActivity(intent)
        } catch (e: Exception) {
            Log.e("INE_SERVICE", "Error al invocar servicio INE: ${e.message}")
        }
    }
    
    private fun handleSuccessResult(jsonResult: String?) {
        // Implementar lógica para procesar el resultado exitoso
        // El JSON contiene los datos extraídos de la credencial INE
    }
    
    private fun handleErrorResult(error: String?) {
        // Implementar lógica para manejar errores
    }
}
```

### Ejemplo de Invocación en Java

```java
import android.content.Intent;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.os.ResultReceiver;
import android.util.Log;

public class MainActivity extends AppCompatActivity {
    
    private ResultReceiver ineResultReceiver = new ResultReceiver(new Handler(Looper.getMainLooper())) {
        @Override
        protected void onReceiveResult(int resultCode, Bundle resultData) {
            switch (resultCode) {
                case RESULT_OK:
                    String jsonResult = resultData.getString("result");
                    Log.d("INE_SERVICE", "Procesamiento exitoso: " + jsonResult);
                    handleSuccessResult(jsonResult);
                    break;
                case RESULT_CANCELED:
                    String error = resultData.getString("error");
                    Log.e("INE_SERVICE", "Error en procesamiento: " + error);
                    handleErrorResult(error);
                    break;
            }
        }
    };
    
    private void invokeIneService(String imagePath, String side) {
        Intent intent = new Intent();
        intent.setClassName(
            "mx.d3c.dev.atom_ocr_ai_m_v3",
            "mx.d3c.dev.atom_ocr_ai_m_v3.IneServiceActivity"
        );
        intent.putExtra("imagePath", imagePath);
        intent.putExtra("side", side);
        intent.putExtra("resultReceiver", ineResultReceiver);
        
        try {
            startActivity(intent);
        } catch (Exception e) {
            Log.e("INE_SERVICE", "Error al invocar servicio INE: " + e.getMessage());
        }
    }
    
    private void handleSuccessResult(String jsonResult) {
        // Implementar lógica para procesar el resultado exitoso
    }
    
    private void handleErrorResult(String error) {
        // Implementar lógica para manejar errores
    }
}
```

## Formato de Respuesta JSON

El servicio devuelve un JSON con la siguiente estructura:

```json
{
  "success": true,
  "data": {
    "nombre": "JUAN PÉREZ GARCÍA",
    "sexo": "H",
    "domicilio": "CALLE EJEMPLO 123, COLONIA CENTRO",
    "claveDeElector": "PRGJN85031512H400",
    "curp": "PEGJ850315HDFRRN09",
    "anoDeRegistro": "2015",
    "fechaDeNacimiento": "15/03/1985",
    "seccion": "1234",
    "vigencia": "2030",
    "tipo": "T2",
    "lado": "frontal",
    "estado": "DISTRITO FEDERAL",
    "municipio": "BENITO JUÁREZ",
    "localidad": "CIUDAD DE MÉXICO"
  }
}
```

### En caso de error:

```json
{
  "success": false,
  "error": "Descripción del error",
  "details": "Detalles adicionales del error"
}
```

## Códigos de Resultado

- `RESULT_OK` (Activity.RESULT_OK): Procesamiento exitoso
- `RESULT_CANCELED` (Activity.RESULT_CANCELED): Error en el procesamiento

## Permisos Requeridos

La aplicación que invoque el servicio debe tener los siguientes permisos:

```xml
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

## Consideraciones Importantes

1. **Ruta de imagen**: La ruta debe ser accesible por la aplicación del servicio INE
2. **Formato de imagen**: Soporta JPG, PNG y otros formatos comunes
3. **Calidad de imagen**: Para mejores resultados, usar imágenes con buena iluminación y enfoque
4. **Lado de credencial**: Especificar correctamente "frontal" o "reverso"
5. **Procesamiento asíncrono**: El resultado se recibe a través del ResultReceiver
6. **Manejo de errores**: Siempre implementar manejo de errores en el ResultReceiver

## Instalación del APK

Para usar este servicio, instalar el APK generado:

```bash
adb install app-release.apk
```

## Soporte

Este servicio está diseñado para funcionar completamente offline y procesar credenciales INE de los tipos T2 y T3. Para cualquier problema o consulta, revisar los logs de la aplicación.

## Versión

Versión actual: 1.0.0
Compatibilidad: Android 8.1+ (API 27+)
Paquete: mx.d3c.dev.atom_ocr_ai_m_v3