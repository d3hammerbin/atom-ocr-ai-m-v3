package mx.d3c.dev.ine;

import android.util.Log;
import java.io.File;
import java.util.concurrent.TimeUnit;
import org.json.JSONObject;
import org.json.JSONException;

/**
 * Procesador nativo que actúa como puente entre el servicio Android
 * y el motor de procesamiento de credenciales INE implementado en Dart/Flutter
 */
public class IneNativeProcessor {
    private static final String TAG = "IneNativeProcessor";
    
    // Cargar la librería nativa
    static {
        try {
            System.loadLibrary("ine_processor_native");
            Log.d(TAG, "Librería nativa cargada exitosamente");
        } catch (UnsatisfiedLinkError e) {
            Log.e(TAG, "Error cargando librería nativa", e);
        }
    }
    
    /**
     * Procesa una credencial INE desde una imagen
     * @param imagePath Ruta absoluta de la imagen
     * @return Resultado del procesamiento
     */
    public static CredentialResult processCredential(String imagePath) {
        Log.d(TAG, "Procesando credencial: " + imagePath);
        
        long startTime = System.currentTimeMillis();
        
        try {
            // Validar entrada
            if (imagePath == null || imagePath.trim().isEmpty()) {
                throw new IllegalArgumentException("Ruta de imagen no puede ser nula o vacía");
            }
            
            File imageFile = new File(imagePath);
            if (!imageFile.exists()) {
                throw new IllegalArgumentException("Archivo no encontrado: " + imagePath);
            }
            
            // Llamar al método nativo
            String jsonResult = processCredentialNative(imagePath);
            
            if (jsonResult == null || jsonResult.trim().isEmpty()) {
                throw new RuntimeException("El procesamiento nativo no devolvió resultados");
            }
            
            // Parsear resultado JSON
            CredentialResult result = CredentialResult.fromJson(jsonResult);
            
            // Calcular tiempo de procesamiento
            long processingTime = System.currentTimeMillis() - startTime;
            result.setProcessingTimeMs(processingTime);
            
            // Validar si la credencial es aceptable
            boolean isAcceptable = validateCredentialResult(result);
            result.setAcceptable(isAcceptable);
            
            Log.d(TAG, "Procesamiento completado en " + processingTime + "ms");
            Log.d(TAG, "Credencial aceptable: " + isAcceptable);
            
            return result;
            
        } catch (Exception e) {
            Log.e(TAG, "Error procesando credencial", e);
            
            // Crear resultado de error
            CredentialResult errorResult = new CredentialResult();
            errorResult.setErrorMessage("Error procesando credencial: " + e.getMessage());
            errorResult.setAcceptable(false);
            errorResult.setProcessingTimeMs(System.currentTimeMillis() - startTime);
            
            return errorResult;
        }
    }
    
    /**
     * Verifica si una imagen contiene una credencial INE válida
     * @param imagePath Ruta absoluta de la imagen
     * @return true si es una credencial INE válida
     */
    public static boolean isValidIneCredential(String imagePath) {
        Log.d(TAG, "Validando credencial INE: " + imagePath);
        
        try {
            // Validar entrada
            if (imagePath == null || imagePath.trim().isEmpty()) {
                return false;
            }
            
            File imageFile = new File(imagePath);
            if (!imageFile.exists()) {
                return false;
            }
            
            // Llamar al método nativo
            return isValidIneCredentialNative(imagePath);
            
        } catch (Exception e) {
            Log.e(TAG, "Error validando credencial", e);
            return false;
        }
    }
    
    /**
     * Valida si un resultado de credencial cumple con los requisitos mínimos
     */
    private static boolean validateCredentialResult(CredentialResult result) {
        if (result == null) {
            return false;
        }
        
        // Verificar campos básicos requeridos
        if (isEmpty(result.getNombre()) || 
            isEmpty(result.getClaveElector()) || 
            isEmpty(result.getCurp()) || 
            isEmpty(result.getTipo())) {
            return false;
        }
        
        // Validar formato de CURP
        if (!isValidCurpFormat(result.getCurp())) {
            return false;
        }
        
        // Validar clave de elector
        if (!isValidClaveElector(result.getClaveElector())) {
            return false;
        }
        
        // Validar tipo de credencial
        if (!isValidCredentialType(result.getTipo())) {
            return false;
        }
        
        return true;
    }
    
    /**
     * Verifica si una cadena está vacía o nula
     */
    private static boolean isEmpty(String str) {
        return str == null || str.trim().isEmpty();
    }
    
    /**
     * Valida formato básico de CURP
     */
    private static boolean isValidCurpFormat(String curp) {
        if (isEmpty(curp)) {
            return false;
        }
        
        String cleanCurp = curp.toUpperCase().replaceAll("[^A-Z0-9]", "");
        return cleanCurp.length() == 18 && cleanCurp.matches("^[A-Z]{4}[0-9]{6}[HM][A-Z]{5}[0-9A-Z][0-9]$");
    }
    
    /**
     * Valida formato de clave de elector
     */
    private static boolean isValidClaveElector(String clave) {
        if (isEmpty(clave)) {
            return false;
        }
        
        String cleanClave = clave.toUpperCase().replaceAll("[^A-Z0-9]", "");
        return cleanClave.length() == 18 && cleanClave.matches("^[A-Z0-9]{18}$");
    }
    
    /**
     * Valida tipo de credencial
     */
    private static boolean isValidCredentialType(String tipo) {
        return "t2".equals(tipo) || "t3".equals(tipo);
    }
    
    // Métodos nativos (implementados en C/C++ o Dart FFI)
    
    /**
     * Procesa una credencial INE usando el motor nativo
     * @param imagePath Ruta de la imagen
     * @return JSON con el resultado del procesamiento
     */
    private static native String processCredentialNative(String imagePath);
    
    /**
     * Verifica si una imagen es una credencial INE válida
     * @param imagePath Ruta de la imagen
     * @return true si es válida
     */
    private static native boolean isValidIneCredentialNative(String imagePath);
    
    /**
     * Obtiene información sobre las capacidades del procesador nativo
     * @return JSON con información de capacidades
     */
    public static native String getNativeProcessorInfo();
    
    /**
     * Inicializa el procesador nativo con configuración específica
     * @param configJson Configuración en formato JSON
     * @return true si la inicialización fue exitosa
     */
    public static native boolean initializeNativeProcessor(String configJson);
    
    /**
     * Libera recursos del procesador nativo
     */
    public static native void releaseNativeProcessor();
}