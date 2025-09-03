package mx.d3c.dev.ine;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
import android.os.Handler;
import android.os.ResultReceiver;
import android.util.Log;
import androidx.work.WorkInfo;
import androidx.work.WorkManager;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import java.util.Map;

/**
 * ResultReceiver para manejar resultados de procesamiento asíncrono
 * Actúa como puente entre WorkManager y los callbacks AIDL
 */
public class IneProcessingResultReceiver extends ResultReceiver {
    private static final String TAG = "IneProcessingResultReceiver";
    
    // Códigos de resultado
    public static final int RESULT_SUCCESS = 0;
    public static final int RESULT_ERROR = 1;
    public static final int RESULT_PROGRESS = 2;
    public static final int RESULT_CANCELLED = 3;
    
    // Claves para datos del bundle
    public static final String KEY_TASK_ID = "taskId";
    public static final String KEY_RESULT_JSON = "resultJson";
    public static final String KEY_ERROR_CODE = "errorCode";
    public static final String KEY_ERROR_MESSAGE = "errorMessage";
    public static final String KEY_PROGRESS = "progress";
    public static final String KEY_STATUS = "status";
    
    // Mapa de callbacks registrados por taskId
    private static final Map<String, IIneProcessorCallback> callbackMap = new ConcurrentHashMap<>();
    
    private final Context context;
    
    public IneProcessingResultReceiver(Handler handler, Context context) {
        super(handler);
        this.context = context;
    }
    
    /**
     * Registra un callback para una tarea específica
     */
    public static void registerCallback(String taskId, IIneProcessorCallback callback) {
        if (taskId != null && callback != null) {
            callbackMap.put(taskId, callback);
            Log.d(TAG, "Callback registrado para tarea: " + taskId);
        }
    }
    
    /**
     * Desregistra un callback
     */
    public static void unregisterCallback(String taskId) {
        if (taskId != null) {
            callbackMap.remove(taskId);
            Log.d(TAG, "Callback desregistrado para tarea: " + taskId);
        }
    }
    
    /**
     * Obtiene un callback registrado
     */
    public static IIneProcessorCallback getCallback(String taskId) {
        return taskId != null ? callbackMap.get(taskId) : null;
    }
    
    @Override
    protected void onReceiveResult(int resultCode, Bundle resultData) {
        super.onReceiveResult(resultCode, resultData);
        
        if (resultData == null) {
            Log.w(TAG, "Datos de resultado nulos");
            return;
        }
        
        String taskId = resultData.getString(KEY_TASK_ID);
        if (taskId == null) {
            Log.w(TAG, "ID de tarea no encontrado en los datos de resultado");
            return;
        }
        
        IIneProcessorCallback callback = getCallback(taskId);
        if (callback == null) {
            Log.w(TAG, "No hay callback registrado para la tarea: " + taskId);
            return;
        }
        
        try {
            switch (resultCode) {
                case RESULT_SUCCESS:
                    handleSuccess(callback, taskId, resultData);
                    break;
                    
                case RESULT_ERROR:
                    handleError(callback, taskId, resultData);
                    break;
                    
                case RESULT_PROGRESS:
                    handleProgress(callback, taskId, resultData);
                    break;
                    
                case RESULT_CANCELLED:
                    handleCancellation(callback, taskId, resultData);
                    break;
                    
                default:
                    Log.w(TAG, "Código de resultado desconocido: " + resultCode);
                    break;
            }
        } catch (Exception e) {
            Log.e(TAG, "Error manejando resultado para tarea " + taskId, e);
        }
    }
    
    /**
     * Maneja resultado exitoso
     */
    private void handleSuccess(IIneProcessorCallback callback, String taskId, Bundle data) {
        try {
            String resultJson = data.getString(KEY_RESULT_JSON);
            if (resultJson != null) {
                CredentialResult result = CredentialResult.fromJson(resultJson);
                callback.onProcessingComplete(taskId, result);
                Log.d(TAG, "Procesamiento completado exitosamente para tarea: " + taskId);
            } else {
                callback.onProcessingError(taskId, IneProcessorService.ERROR_UNKNOWN, "Resultado JSON nulo");
            }
            
            // Limpiar callback después del éxito
            unregisterCallback(taskId);
            
        } catch (Exception e) {
            Log.e(TAG, "Error manejando éxito para tarea " + taskId, e);
            try {
                callback.onProcessingError(taskId, IneProcessorService.ERROR_UNKNOWN, "Error interno: " + e.getMessage());
            } catch (Exception callbackError) {
                Log.e(TAG, "Error llamando callback de error", callbackError);
            }
        }
    }
    
    /**
     * Maneja errores
     */
    private void handleError(IIneProcessorCallback callback, String taskId, Bundle data) {
        try {
            int errorCode = data.getInt(KEY_ERROR_CODE, IneProcessorService.ERROR_UNKNOWN);
            String errorMessage = data.getString(KEY_ERROR_MESSAGE, "Error desconocido");
            
            callback.onProcessingError(taskId, errorCode, errorMessage);
            Log.d(TAG, "Error reportado para tarea " + taskId + ": " + errorMessage);
            
            // Limpiar callback después del error
            unregisterCallback(taskId);
            
        } catch (Exception e) {
            Log.e(TAG, "Error manejando error para tarea " + taskId, e);
        }
    }
    
    /**
     * Maneja actualizaciones de progreso
     */
    private void handleProgress(IIneProcessorCallback callback, String taskId, Bundle data) {
        try {
            int progress = data.getInt(KEY_PROGRESS, 0);
            String status = data.getString(KEY_STATUS, "Procesando...");
            
            callback.onProgressUpdate(taskId, progress, status);
            Log.d(TAG, "Progreso actualizado para tarea " + taskId + ": " + progress + "% - " + status);
            
        } catch (Exception e) {
            Log.e(TAG, "Error manejando progreso para tarea " + taskId, e);
        }
    }
    
    /**
     * Maneja cancelaciones
     */
    private void handleCancellation(IIneProcessorCallback callback, String taskId, Bundle data) {
        try {
            callback.onProcessingCancelled(taskId);
            Log.d(TAG, "Procesamiento cancelado para tarea: " + taskId);
            
            // Limpiar callback después de la cancelación
            unregisterCallback(taskId);
            
        } catch (Exception e) {
            Log.e(TAG, "Error manejando cancelación para tarea " + taskId, e);
        }
    }
    
    /**
     * Notifica resultado desde WorkManager
     */
    public static void notifyWorkResult(String taskId, WorkInfo workInfo) {
        IIneProcessorCallback callback = getCallback(taskId);
        if (callback == null) {
            Log.w(TAG, "No hay callback para notificar resultado de trabajo: " + taskId);
            return;
        }
        
        try {
            WorkInfo.State state = workInfo.getState();
            
            switch (state) {
                case SUCCEEDED:
                    String resultJson = workInfo.getOutputData().getString("result");
                    if (resultJson != null) {
                        CredentialResult result = CredentialResult.fromJson(resultJson);
                        callback.onProcessingComplete(taskId, result);
                    }
                    unregisterCallback(taskId);
                    break;
                    
                case FAILED:
                    int errorCode = workInfo.getOutputData().getInt("errorCode", IneProcessorService.ERROR_UNKNOWN);
                    String errorMessage = workInfo.getOutputData().getString("error");
                    callback.onProcessingError(taskId, errorCode, errorMessage);
                    unregisterCallback(taskId);
                    break;
                    
                case CANCELLED:
                    callback.onProcessingCancelled(taskId);
                    unregisterCallback(taskId);
                    break;
                    
                case RUNNING:
                    // Obtener progreso si está disponible
                    int progress = workInfo.getProgress().getInt("progress", 0);
                    String status = workInfo.getProgress().getString("status");
                    if (status != null) {
                        callback.onProgressUpdate(taskId, progress, status);
                    }
                    break;
                    
                default:
                    // Estados ENQUEUED, BLOCKED no requieren notificación
                    break;
            }
            
        } catch (Exception e) {
            Log.e(TAG, "Error notificando resultado de trabajo para tarea " + taskId, e);
        }
    }
    
    /**
     * Limpia todos los callbacks registrados
     */
    public static void clearAllCallbacks() {
        callbackMap.clear();
        Log.d(TAG, "Todos los callbacks han sido limpiados");
    }
}