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
     * Procesa una credencial INE desde una imagen extrayendo datos completos
     * Para el lado frontal: extrae datos específicos según tipo T2/T3
     * Para el lado reverso: extrae únicamente datos MRZ
     * @param imagePath Ruta absoluta de la imagen
     * @param documentSide Lado del documento ("front" o "back")
     * @return Resultado del procesamiento con datos completos del lado frontal o MRZ del reverso
     */
    public static CredentialResult processCredential(String imagePath, String documentSide) {
        Log.d(TAG, "Procesando credencial: " + imagePath + ", lado: " + documentSide);
        
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
            
            // Llamar al método nativo con el lado del documento
            String jsonResult = processCredentialNative(imagePath, documentSide);
            
            if (jsonResult == null || jsonResult.trim().isEmpty()) {
                throw new RuntimeException("El procesamiento nativo no devolvió resultados");
            }
            
            // Parsear resultado JSON
            CredentialResult result = CredentialResult.fromJson(jsonResult);
            
            // Calcular tiempo de procesamiento
            long processingTime = System.currentTimeMillis() - startTime;
            result.setProcessingTimeMs(processingTime);
            
            // Validar si el resultado es aceptable según el lado del documento
            boolean isAcceptable = validateCredentialResult(result, documentSide);
            result.setAcceptable(isAcceptable);
            
            // Establecer el lado del documento y detectar tipo de credencial si es frontal
            result.setDocumentSide(documentSide);
            if ("front".equalsIgnoreCase(documentSide)) {
                String credentialType = detectCredentialType(result);
                result.setCredentialType(credentialType);
            }
            
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
     * Verifica si una imagen contiene un MRZ válido en el lado especificado
     * @param imagePath Ruta absoluta de la imagen
     * @param documentSide Lado del documento ("front" o "back")
     * @return true si contiene un MRZ válido
     */
    public static boolean isValidIneCredential(String imagePath, String documentSide) {
        Log.d(TAG, "Validando MRZ en credencial: " + imagePath + ", lado: " + documentSide);
        
        try {
            // Validar entrada
            if (imagePath == null || imagePath.trim().isEmpty()) {
                return false;
            }
            
            File imageFile = new File(imagePath);
            if (!imageFile.exists()) {
                return false;
            }
            
            // Llamar al método nativo con el lado del documento
            return isValidIneCredentialNative(imagePath, documentSide);
            
        } catch (Exception e) {
            Log.e(TAG, "Error validando credencial", e);
            return false;
        }
    }
    
    /**
     * Valida si el resultado contiene datos mínimos requeridos según el lado del documento
     * @param result Resultado del procesamiento
     * @param documentSide Lado del documento ("front" o "back")
     * @return true si el resultado es válido y aceptable
     */
    private static boolean validateCredentialResult(CredentialResult result, String documentSide) {
        if (result == null) {
            return false;
        }
        
        if ("back".equalsIgnoreCase(documentSide)) {
            // Para el lado reverso, validar solo MRZ
            return validateMrzData(result);
        } else {
            // Para el lado frontal, validar datos básicos de la credencial
            return validateFrontData(result);
        }
    }
    
    /**
     * Valida los datos del MRZ (lado reverso)
     */
    private static boolean validateMrzData(CredentialResult result) {
        if (isEmpty(result.getMrzContent())) {
            Log.w(TAG, "MRZ vacío o nulo");
            return false;
        }
        
        // Verificar campos críticos del MRZ
        boolean hasRequiredFields = !isEmpty(result.getMrzDocumentNumber()) &&
                                   !isEmpty(result.getMrzName()) &&
                                   !isEmpty(result.getMrzBirthDate());
        
        if (!hasRequiredFields) {
            Log.w(TAG, "Faltan campos críticos en el MRZ");
            return false;
        }
        
        Log.d(TAG, "MRZ validado exitosamente");
        return true;
    }
    
    /**
     * Valida los datos del lado frontal
     */
    private static boolean validateFrontData(CredentialResult result) {
        // Campos comunes requeridos para T2 y T3
        boolean hasCommonFields = !isEmpty(result.getNombre()) &&
                                 !isEmpty(result.getCurp()) &&
                                 !isEmpty(result.getClaveElector()) &&
                                 !isEmpty(result.getFechaNacimiento()) &&
                                 !isEmpty(result.getSexo());
        
        if (!hasCommonFields) {
            Log.w(TAG, "Faltan campos críticos del lado frontal");
            return false;
        }
        
        Log.d(TAG, "Datos frontales validados exitosamente");
        return true;
    }
    
    /**
     * Detecta el tipo de credencial (T2 o T3) basado en los campos disponibles
     */
    private static String detectCredentialType(CredentialResult result) {
        // T2 tiene campos adicionales como Estado, Municipio, Localidad, Emisión
        // T3 no tiene estos campos
        boolean hasT2Fields = !isEmpty(result.getEstado()) ||
                              !isEmpty(result.getMunicipio()) ||
                              !isEmpty(result.getLocalidad()) ||
                              !isEmpty(result.getEmision());
        
        String type = hasT2Fields ? "T2" : "T3";
        Log.d(TAG, "Tipo de credencial detectado: " + type);
        return type;
    }
    
    /**
     * Verifica si una cadena está vacía o nula
     */
    private static boolean isEmpty(String str) {
        return str == null || str.trim().isEmpty();
    }
    
    /**
     * Simula el procesamiento nativo para pruebas
     * Para el lado frontal: genera datos completos según tipo de credencial
     * Para el lado reverso: genera solo datos MRZ
     * En producción, este método sería reemplazado por la implementación JNI real
     */
    private static String simulateNativeProcessing(String imagePath, String documentSide) {
        Log.d(TAG, "Simulando procesamiento nativo para: " + imagePath + ", lado: " + documentSide);
        
        JSONObject result = new JSONObject();
        try {
            if ("front".equalsIgnoreCase(documentSide)) {
                // Simular datos del lado frontal (T2 completo como ejemplo)
                result.put("nombre", "JUAN CARLOS GARCIA LOPEZ");
                result.put("domicilio", "CALLE REFORMA 123 COL CENTRO");
                result.put("claveElector", "GALJ900101HDFRRN09");
                result.put("curp", "GALJ900101HDFRRN09");
                result.put("anoRegistro", "2020");
                result.put("fechaNacimiento", "01/01/1990");
                result.put("sexo", "H");
                result.put("seccion", "1234");
                result.put("vigencia", "2030");
                result.put("estado", "DISTRITO FEDERAL");
                result.put("municipio", "CUAUHTEMOC");
                result.put("localidad", "CENTRO");
                result.put("emision", "2020");
            } else {
                // Simular datos MRZ del lado reverso
                result.put("mrzContent", "IDMEX123456789012345678901234567890123456789012345678901234567890");
                result.put("mrzDocumentNumber", "123456789");
                result.put("mrzNationality", "MEX");
                result.put("mrzBirthDate", "900101");
                result.put("mrzExpiryDate", "301231");
                result.put("mrzSex", "M");
                result.put("mrzName", "GARCIA<LOPEZ<<JUAN<CARLOS");
            }
            
            // Simular tiempo de procesamiento
            Thread.sleep(100);
            
        } catch (JSONException | InterruptedException e) {
            Log.e(TAG, "Error en simulación: " + e.getMessage());
            return "{}";
        }
        
        return result.toString();
    }

    
    // Métodos nativos (implementados en C/C++ o Dart FFI)
    
    /**
     * Método nativo que procesa la imagen y extrae datos completos
     * Para el lado frontal: extrae datos específicos según tipo T2/T3
     * Para el lado reverso: extrae únicamente datos MRZ
     * Este método debe ser implementado en C/C++ y vinculado mediante JNI
     * 
     * @param imagePath Ruta absoluta de la imagen a procesar
     * @param documentSide Lado del documento ("front" o "back")
     * @return String JSON con los datos extraídos según el lado del documento
     */
    private static native String processCredentialNative(String imagePath, String documentSide);
    
    /**
     * Verifica si una imagen contiene un MRZ válido en el lado especificado
     * @param imagePath Ruta de la imagen
     * @param documentSide Lado del documento ("front" o "back")
     * @return true si contiene MRZ válido
     */
    private static native boolean isValidIneCredentialNative(String imagePath, String documentSide);
    
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