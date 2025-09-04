package mx.d3c.dev.ine;

import android.app.Service;
import android.content.Intent;
import android.os.IBinder;
import android.os.RemoteException;
import android.util.Log;
import androidx.work.WorkManager;
import androidx.work.OneTimeWorkRequest;
import androidx.work.Data;
import androidx.work.WorkInfo;
import androidx.lifecycle.Observer;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.UUID;
import org.json.JSONObject;
import org.json.JSONException;

/**
 * Servicio Android que procesa credenciales INE mexicanas
 * Para el lado frontal: extrae datos completos según tipo T2/T3
 * Para el lado reverso: extrae únicamente datos MRZ
 * Implementa la interfaz AIDL para comunicación con React Native
 * Utiliza WorkManager para procesamiento en background
 */
public class IneProcessorService extends Service {
    private static final String TAG = "IneProcessorService";
    private static final String SERVICE_VERSION = "1.0.0";
    
    // Mapa para rastrear tareas activas
    private final ConcurrentHashMap<String, IIneProcessorCallback> activeCallbacks = new ConcurrentHashMap<>();
    private final ConcurrentHashMap<String, UUID> workRequestIds = new ConcurrentHashMap<>();
    
    // Executor para tareas síncronas
    private ExecutorService executorService;
    
    // Códigos de error
    public static final int ERROR_FILE_NOT_FOUND = 1001;
    public static final int ERROR_INVALID_IMAGE = 1002;
    public static final int ERROR_PROCESSING_FAILED = 1003;
    public static final int ERROR_TASK_CANCELLED = 1004;
    public static final int ERROR_UNKNOWN = 1999;

    @Override
    public void onCreate() {
        super.onCreate();
        Log.d(TAG, "IneProcessorService creado");
        executorService = Executors.newCachedThreadPool();
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        Log.d(TAG, "IneProcessorService destruido");
        if (executorService != null) {
            executorService.shutdown();
        }
        // Cancelar todas las tareas activas
        for (String taskId : workRequestIds.keySet()) {
            cancelProcessing(taskId);
        }
    }

    @Override
    public IBinder onBind(Intent intent) {
        Log.d(TAG, "Cliente conectado al servicio");
        return binder;
    }

    @Override
    public boolean onUnbind(Intent intent) {
        Log.d(TAG, "Cliente desconectado del servicio");
        return super.onUnbind(intent);
    }

    /**
     * Implementación de la interfaz AIDL
     */
    private final IIneProcessorService.Stub binder = new IIneProcessorService.Stub() {
        
        @Override
        public String processCredentialAsync(String imagePath, String documentSide, IIneProcessorCallback callback) throws RemoteException {
            Log.d(TAG, "Iniciando procesamiento asíncrono: " + imagePath + ", lado: " + documentSide);
            
            String taskId = UUID.randomUUID().toString();
            activeCallbacks.put(taskId, callback);
            
            try {
                // Crear datos para WorkManager
                Data inputData = new Data.Builder()
                    .putString("imagePath", imagePath)
                    .putString("documentSide", documentSide)
                    .putString("taskId", taskId)
                    .build();
                
                // Crear y encolar trabajo
                OneTimeWorkRequest workRequest = new OneTimeWorkRequest.Builder(IneProcessingWorker.class)
                    .setInputData(inputData)
                    .build();
                
                workRequestIds.put(taskId, workRequest.getId());
                WorkManager.getInstance(getApplicationContext()).enqueue(workRequest);
                
                // Observar el progreso del trabajo
                observeWorkProgress(taskId, workRequest.getId(), callback);
                
                Log.d(TAG, "Tarea encolada con ID: " + taskId);
                return taskId;
                
            } catch (Exception e) {
                Log.e(TAG, "Error iniciando procesamiento asíncrono", e);
                activeCallbacks.remove(taskId);
                callback.onProcessingError(taskId, ERROR_UNKNOWN, "Error iniciando procesamiento: " + e.getMessage());
                return null;
            }
        }
        
        @Override
        public String processCredentialSync(String imagePath, String documentSide) throws RemoteException {
            Log.d(TAG, "Iniciando procesamiento síncrono: " + imagePath + ", lado: " + documentSide);
            
            try {
                // Validar que el archivo existe
                if (!new java.io.File(imagePath).exists()) {
                    throw new RuntimeException("Archivo no encontrado: " + imagePath);
                }
                
                // Procesar la credencial usando el procesador nativo con el lado especificado
                CredentialResult result = IneNativeProcessor.processCredential(imagePath, documentSide);
                
                if (result != null) {
                    Log.d(TAG, "Procesamiento síncrono completado exitosamente");
                    return result.toJson();
                } else {
                    throw new RuntimeException("El procesamiento no devolvió resultados");
                }
                
            } catch (Exception e) {
                Log.e(TAG, "Error en procesamiento síncrono", e);
                
                // Crear resultado de error
                CredentialResult errorResult = new CredentialResult();
                errorResult.setErrorMessage("Error procesando credencial: " + e.getMessage());
                errorResult.setAcceptable(false);
                
                return errorResult.toJson();
            }
        }
        
        @Override
        public boolean isValidIneCredential(String imagePath, String documentSide) throws RemoteException {
            Log.d(TAG, "Validando credencial INE: " + imagePath + ", lado: " + documentSide);
            
            try {
                // Validar que el archivo existe
                if (!new java.io.File(imagePath).exists()) {
                    return false;
                }
                
                // Usar el procesador nativo para validar con el lado especificado
                return IneNativeProcessor.isValidIneCredential(imagePath, documentSide);
                
            } catch (Exception e) {
                Log.e(TAG, "Error validando credencial", e);
                return false;
            }
        }
        
        @Override
        public boolean cancelProcessing(String taskId) throws RemoteException {
            Log.d(TAG, "Cancelando tarea: " + taskId);
            
            try {
                UUID workId = workRequestIds.get(taskId);
                if (workId != null) {
                    WorkManager.getInstance(getApplicationContext()).cancelWorkById(workId);
                    
                    // Notificar cancelación
                    IIneProcessorCallback callback = activeCallbacks.get(taskId);
                    if (callback != null) {
                        callback.onProcessingCancelled(taskId);
                    }
                    
                    // Limpiar referencias
                    activeCallbacks.remove(taskId);
                    workRequestIds.remove(taskId);
                    
                    return true;
                }
                return false;
                
            } catch (Exception e) {
                Log.e(TAG, "Error cancelando tarea", e);
                return false;
            }
        }
        
        @Override
        public String getTaskStatus(String taskId) throws RemoteException {
            try {
                UUID workId = workRequestIds.get(taskId);
                if (workId != null) {
                    WorkInfo workInfo = WorkManager.getInstance(getApplicationContext())
                        .getWorkInfoById(workId).get();
                    
                    if (workInfo != null) {
                        return workInfo.getState().name();
                    }
                }
                return "UNKNOWN";
                
            } catch (Exception e) {
                Log.e(TAG, "Error obteniendo estado de tarea", e);
                return "ERROR";
            }
        }
        
        @Override
        public String getServiceInfo() throws RemoteException {
            try {
                JSONObject info = new JSONObject();
                info.put("serviceName", "IneProcessorService");
                info.put("version", SERVICE_VERSION);
                info.put("supportedTypes", new org.json.JSONArray().put("t2").put("t3"));
                info.put("capabilities", new org.json.JSONArray()
                    .put("mrz_extraction")
                    .put("front_data_extraction")
                    .put("credential_type_detection")
                    .put("t2_full_extraction")
                    .put("t3_full_extraction")
                );
                info.put("maxImageSize", 10 * 1024 * 1024); // 10MB
                info.put("supportedFormats", new org.json.JSONArray()
                    .put("jpg")
                    .put("jpeg")
                    .put("png")
                    .put("bmp")
                );
                
                return info.toString();
                
            } catch (JSONException e) {
                Log.e(TAG, "Error creando información del servicio", e);
                return "{}";
            }
        }
    };
    
    /**
     * Observa el progreso de una tarea de WorkManager
     */
    private void observeWorkProgress(String taskId, UUID workId, IIneProcessorCallback callback) {
        WorkManager.getInstance(getApplicationContext())
            .getWorkInfoByIdLiveData(workId)
            .observeForever(new Observer<WorkInfo>() {
                @Override
                public void onChanged(WorkInfo workInfo) {
                    if (workInfo != null) {
                        try {
                            switch (workInfo.getState()) {
                                case RUNNING:
                                    Data progress = workInfo.getProgress();
                                    int progressValue = progress.getInt("progress", 0);
                                    String status = progress.getString("status");
                                    callback.onProgressUpdate(taskId, progressValue, status != null ? status : "Procesando...");
                                    break;
                                    
                                case SUCCEEDED:
                                    String result = workInfo.getOutputData().getString("result");
                                    callback.onProcessingComplete(taskId, result != null ? result : "{}");
                                    cleanup(taskId);
                                    break;
                                    
                                case FAILED:
                                    String error = workInfo.getOutputData().getString("error");
                                    int errorCode = workInfo.getOutputData().getInt("errorCode", ERROR_PROCESSING_FAILED);
                                    callback.onProcessingError(taskId, errorCode, error != null ? error : "Error desconocido");
                                    cleanup(taskId);
                                    break;
                                    
                                case CANCELLED:
                                    callback.onProcessingCancelled(taskId);
                                    cleanup(taskId);
                                    break;
                            }
                        } catch (RemoteException e) {
                            Log.e(TAG, "Error notificando progreso", e);
                            cleanup(taskId);
                        }
                    }
                }
            });
    }
    
    /**
     * Limpia las referencias de una tarea completada
     */
    private void cleanup(String taskId) {
        activeCallbacks.remove(taskId);
        workRequestIds.remove(taskId);
    }
}