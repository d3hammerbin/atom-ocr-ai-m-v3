package com.ineprocessor;

import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.ServiceConnection;
import android.os.IBinder;
import android.os.RemoteException;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.modules.core.DeviceEventManagerModule;

import org.json.JSONException;
import org.json.JSONObject;

import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

import mx.d3c.dev.ine.IIneProcessorService;
import mx.d3c.dev.ine.IIneProcessorCallback;
import mx.d3c.dev.ine.CredentialResult;

/**
 * Módulo React Native para procesamiento de credenciales INE
 * Conecta con el Android Service nativo mediante AIDL
 */
public class IneProcessorModule extends ReactContextBaseJavaModule {
    private static final String TAG = "IneProcessorModule";
    private static final String MODULE_NAME = "IneProcessor";
    
    // Eventos que se envían a JavaScript
    private static final String EVENT_PROGRESS = "IneProcessor_Progress";
    private static final String EVENT_COMPLETE = "IneProcessor_Complete";
    private static final String EVENT_ERROR = "IneProcessor_Error";
    private static final String EVENT_CANCELLED = "IneProcessor_Cancelled";
    
    private final ReactApplicationContext reactContext;
    private IIneProcessorService ineService;
    private boolean isServiceBound = false;
    private final Map<String, Promise> pendingPromises = new ConcurrentHashMap<>();
    
    // Conexión al servicio Android
    private final ServiceConnection serviceConnection = new ServiceConnection() {
        @Override
        public void onServiceConnected(ComponentName name, IBinder service) {
            Log.d(TAG, "Servicio INE conectado");
            ineService = IIneProcessorService.Stub.asInterface(service);
            isServiceBound = true;
            
            // Resolver promesas pendientes de conexión
            synchronized (pendingPromises) {
                for (Map.Entry<String, Promise> entry : pendingPromises.entrySet()) {
                    if ("service_connection".equals(entry.getKey())) {
                        entry.getValue().resolve(true);
                        pendingPromises.remove(entry.getKey());
                        break;
                    }
                }
            }
        }
        
        @Override
        public void onServiceDisconnected(ComponentName name) {
            Log.d(TAG, "Servicio INE desconectado");
            ineService = null;
            isServiceBound = false;
            
            // Rechazar promesas pendientes
            synchronized (pendingPromises) {
                for (Map.Entry<String, Promise> entry : pendingPromises.entrySet()) {
                    entry.getValue().reject("SERVICE_DISCONNECTED", "El servicio se desconectó inesperadamente");
                }
                pendingPromises.clear();
            }
        }
    };
    
    public IneProcessorModule(ReactApplicationContext reactContext) {
        super(reactContext);
        this.reactContext = reactContext;
        bindToService();
    }
    
    @Override
    @NonNull
    public String getName() {
        return MODULE_NAME;
    }
    
    @Override
    public Map<String, Object> getConstants() {
        final Map<String, Object> constants = new HashMap<>();
        
        // Códigos de error
        constants.put("ERROR_UNKNOWN", 0);
        constants.put("ERROR_FILE_NOT_FOUND", 1);
        constants.put("ERROR_INVALID_IMAGE", 2);
        constants.put("ERROR_PROCESSING_FAILED", 3);
        constants.put("ERROR_SERVICE_UNAVAILABLE", 4);
        constants.put("ERROR_PERMISSION_DENIED", 5);
        constants.put("ERROR_TIMEOUT", 6);
        
        // Estados de procesamiento
        constants.put("STATUS_PENDING", "pending");
        constants.put("STATUS_PROCESSING", "processing");
        constants.put("STATUS_COMPLETED", "completed");
        constants.put("STATUS_FAILED", "failed");
        constants.put("STATUS_CANCELLED", "cancelled");
        
        return constants;
    }
    
    /**
     * Conecta al servicio Android
     */
    private void bindToService() {
        try {
            Intent intent = new Intent();
            intent.setComponent(new ComponentName("mx.d3c.dev.ine", "mx.d3c.dev.ine.IneProcessorService"));
            intent.setAction("mx.d3c.dev.ine.INE_PROCESSOR_SERVICE");
            
            boolean bound = reactContext.bindService(intent, serviceConnection, Context.BIND_AUTO_CREATE);
            Log.d(TAG, "Intentando conectar al servicio: " + bound);
            
        } catch (Exception e) {
            Log.e(TAG, "Error conectando al servicio", e);
        }
    }
    
    /**
     * Procesa una credencial de forma asíncrona
     */
    @ReactMethod
    public void processCredentialAsync(String imagePath, ReadableMap config, Promise promise) {
        if (!isServiceBound || ineService == null) {
            promise.reject("SERVICE_NOT_AVAILABLE", "El servicio de procesamiento no está disponible");
            return;
        }
        
        try {
            String configJson = readableMapToJson(config).toString();
            
            // Crear callback para manejar el resultado
            IIneProcessorCallback callback = new IIneProcessorCallback.Stub() {
                @Override
                public void onProcessingComplete(String taskId, CredentialResult result) throws RemoteException {
                    Log.d(TAG, "Procesamiento completado para tarea: " + taskId);
                    
                    // Enviar evento a JavaScript
                    WritableMap eventData = Arguments.createMap();
                    eventData.putString("taskId", taskId);
                    eventData.putMap("result", credentialResultToWritableMap(result));
                    sendEvent(EVENT_COMPLETE, eventData);
                }
                
                @Override
                public void onProcessingError(String taskId, int errorCode, String errorMessage) throws RemoteException {
                    Log.e(TAG, "Error en procesamiento para tarea " + taskId + ": " + errorMessage);
                    
                    // Enviar evento a JavaScript
                    WritableMap eventData = Arguments.createMap();
                    eventData.putString("taskId", taskId);
                    eventData.putInt("errorCode", errorCode);
                    eventData.putString("errorMessage", errorMessage);
                    sendEvent(EVENT_ERROR, eventData);
                }
                
                @Override
                public void onProgressUpdate(String taskId, int progress, String status) throws RemoteException {
                    Log.d(TAG, "Progreso actualizado para tarea " + taskId + ": " + progress + "% - " + status);
                    
                    // Enviar evento a JavaScript
                    WritableMap eventData = Arguments.createMap();
                    eventData.putString("taskId", taskId);
                    eventData.putInt("progress", progress);
                    eventData.putString("status", status);
                    eventData.putDouble("timestamp", System.currentTimeMillis());
                    sendEvent(EVENT_PROGRESS, eventData);
                }
                
                @Override
                public void onProcessingCancelled(String taskId) throws RemoteException {
                    Log.d(TAG, "Procesamiento cancelado para tarea: " + taskId);
                    
                    // Enviar evento a JavaScript
                    WritableMap eventData = Arguments.createMap();
                    eventData.putString("taskId", taskId);
                    sendEvent(EVENT_CANCELLED, eventData);
                }
            };
            
            // Llamar al servicio
            String taskId = ineService.processCredentialAsync(imagePath, configJson, callback);
            promise.resolve(taskId);
            
        } catch (Exception e) {
            Log.e(TAG, "Error procesando credencial async", e);
            promise.reject("PROCESSING_ERROR", "Error procesando credencial: " + e.getMessage());
        }
    }
    
    /**
     * Procesa una credencial de forma síncrona
     */
    @ReactMethod
    public void processCredential(String imagePath, ReadableMap config, Promise promise) {
        if (!isServiceBound || ineService == null) {
            promise.reject("SERVICE_NOT_AVAILABLE", "El servicio de procesamiento no está disponible");
            return;
        }
        
        try {
            String configJson = readableMapToJson(config).toString();
            CredentialResult result = ineService.processCredential(imagePath, configJson);
            
            WritableMap resultMap = credentialResultToWritableMap(result);
            promise.resolve(resultMap);
            
        } catch (Exception e) {
            Log.e(TAG, "Error procesando credencial", e);
            promise.reject("PROCESSING_ERROR", "Error procesando credencial: " + e.getMessage());
        }
    }
    
    /**
     * Verifica si una imagen es una credencial válida
     */
    @ReactMethod
    public void isValidCredential(String imagePath, Promise promise) {
        if (!isServiceBound || ineService == null) {
            promise.reject("SERVICE_NOT_AVAILABLE", "El servicio de procesamiento no está disponible");
            return;
        }
        
        try {
            boolean isValid = ineService.isValidCredential(imagePath);
            promise.resolve(isValid);
            
        } catch (Exception e) {
            Log.e(TAG, "Error validando credencial", e);
            promise.reject("VALIDATION_ERROR", "Error validando credencial: " + e.getMessage());
        }
    }
    
    /**
     * Cancela una tarea de procesamiento
     */
    @ReactMethod
    public void cancelTask(String taskId, Promise promise) {
        if (!isServiceBound || ineService == null) {
            promise.reject("SERVICE_NOT_AVAILABLE", "El servicio de procesamiento no está disponible");
            return;
        }
        
        try {
            boolean cancelled = ineService.cancelTask(taskId);
            promise.resolve(cancelled);
            
        } catch (Exception e) {
            Log.e(TAG, "Error cancelando tarea", e);
            promise.reject("CANCELLATION_ERROR", "Error cancelando tarea: " + e.getMessage());
        }
    }
    
    /**
     * Obtiene el estado de una tarea
     */
    @ReactMethod
    public void getTaskStatus(String taskId, Promise promise) {
        if (!isServiceBound || ineService == null) {
            promise.reject("SERVICE_NOT_AVAILABLE", "El servicio de procesamiento no está disponible");
            return;
        }
        
        try {
            String status = ineService.getTaskStatus(taskId);
            promise.resolve(status);
            
        } catch (Exception e) {
            Log.e(TAG, "Error obteniendo estado de tarea", e);
            promise.reject("STATUS_ERROR", "Error obteniendo estado: " + e.getMessage());
        }
    }
    
    /**
     * Obtiene información del servicio
     */
    @ReactMethod
    public void getServiceInfo(Promise promise) {
        if (!isServiceBound || ineService == null) {
            promise.reject("SERVICE_NOT_AVAILABLE", "El servicio de procesamiento no está disponible");
            return;
        }
        
        try {
            String infoJson = ineService.getServiceInfo();
            JSONObject info = new JSONObject(infoJson);
            
            WritableMap infoMap = Arguments.createMap();
            infoMap.putString("version", info.optString("version", "1.0.0"));
            infoMap.putBoolean("isAvailable", true);
            
            promise.resolve(infoMap);
            
        } catch (Exception e) {
            Log.e(TAG, "Error obteniendo información del servicio", e);
            promise.reject("INFO_ERROR", "Error obteniendo información: " + e.getMessage());
        }
    }
    
    /**
     * Convierte ReadableMap a JSONObject
     */
    private JSONObject readableMapToJson(ReadableMap readableMap) {
        JSONObject json = new JSONObject();
        
        if (readableMap == null) {
            return json;
        }
        
        try {
            // Configuración por defecto
            json.put("minImageWidth", readableMap.hasKey("minImageWidth") ? readableMap.getInt("minImageWidth") : 800);
            json.put("minImageHeight", readableMap.hasKey("minImageHeight") ? readableMap.getInt("minImageHeight") : 600);
            json.put("maxImageSize", readableMap.hasKey("maxImageSize") ? readableMap.getInt("maxImageSize") : 10485760); // 10MB
            json.put("ocrLanguage", readableMap.hasKey("ocrLanguage") ? readableMap.getString("ocrLanguage") : "spa");
            json.put("ocrMode", readableMap.hasKey("ocrMode") ? readableMap.getString("ocrMode") : "accurate");
            json.put("strictValidation", readableMap.hasKey("strictValidation") ? readableMap.getBoolean("strictValidation") : true);
            json.put("validateCurp", readableMap.hasKey("validateCurp") ? readableMap.getBoolean("validateCurp") : true);
            json.put("validateClaveElector", readableMap.hasKey("validateClaveElector") ? readableMap.getBoolean("validateClaveElector") : true);
            json.put("timeoutMs", readableMap.hasKey("timeoutMs") ? readableMap.getInt("timeoutMs") : 30000);
            
        } catch (JSONException e) {
            Log.e(TAG, "Error convirtiendo ReadableMap a JSON", e);
        }
        
        return json;
    }
    
    /**
     * Convierte CredentialResult a WritableMap
     */
    private WritableMap credentialResultToWritableMap(CredentialResult result) {
        WritableMap map = Arguments.createMap();
        
        if (result == null) {
            return map;
        }
        
        // Información personal
        putStringIfNotNull(map, "nombre", result.getNombre());
        putStringIfNotNull(map, "apellidoPaterno", result.getApellidoPaterno());
        putStringIfNotNull(map, "apellidoMaterno", result.getApellidoMaterno());
        putStringIfNotNull(map, "fechaNacimiento", result.getFechaNacimiento());
        putStringIfNotNull(map, "sexo", result.getSexo());
        
        // Información de identificación
        putStringIfNotNull(map, "curp", result.getCurp());
        putStringIfNotNull(map, "claveElector", result.getClaveElector());
        
        // Información de domicilio
        putStringIfNotNull(map, "domicilio", result.getDomicilio());
        putStringIfNotNull(map, "seccion", result.getSeccion());
        putStringIfNotNull(map, "localidad", result.getLocalidad());
        putStringIfNotNull(map, "municipio", result.getMunicipio());
        putStringIfNotNull(map, "estado", result.getEstado());
        
        // Información de la credencial
        putStringIfNotNull(map, "tipo", result.getTipo());
        putStringIfNotNull(map, "lado", result.getLado());
        putStringIfNotNull(map, "vigencia", result.getVigencia());
        putStringIfNotNull(map, "añoRegistro", result.getAñoRegistro());
        
        // Metadatos
        map.putBoolean("acceptable", result.isAcceptable());
        map.putDouble("processingTimeMs", result.getProcessingTimeMs());
        map.putDouble("confidence", result.getConfidence());
        putStringIfNotNull(map, "errorMessage", result.getErrorMessage());
        
        return map;
    }
    
    /**
     * Añade una cadena al mapa solo si no es nula
     */
    private void putStringIfNotNull(WritableMap map, String key, String value) {
        if (value != null) {
            map.putString(key, value);
        }
    }
    
    /**
     * Envía un evento a JavaScript
     */
    private void sendEvent(String eventName, @Nullable WritableMap params) {
        reactContext
            .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
            .emit(eventName, params);
    }
    
    @Override
    public void onCatalystInstanceDestroy() {
        super.onCatalystInstanceDestroy();
        
        // Desconectar del servicio
        if (isServiceBound) {
            try {
                reactContext.unbindService(serviceConnection);
                isServiceBound = false;
            } catch (Exception e) {
                Log.e(TAG, "Error desconectando del servicio", e);
            }
        }
        
        // Limpiar promesas pendientes
        synchronized (pendingPromises) {
            for (Promise promise : pendingPromises.values()) {
                promise.reject("MODULE_DESTROYED", "El módulo fue destruido");
            }
            pendingPromises.clear();
        }
    }
}