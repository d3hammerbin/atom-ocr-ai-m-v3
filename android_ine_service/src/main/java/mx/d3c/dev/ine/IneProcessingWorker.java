package mx.d3c.dev.ine;

import android.content.Context;
import android.util.Log;
import androidx.annotation.NonNull;
import androidx.work.Data;
import androidx.work.Worker;
import androidx.work.WorkerParameters;
import java.io.File;

/**
 * Worker de WorkManager para procesamiento de credenciales INE en background
 * Maneja el procesamiento asíncrono y reporta progreso
 */
public class IneProcessingWorker extends Worker {
    private static final String TAG = "IneProcessingWorker";
    
    public IneProcessingWorker(@NonNull Context context, @NonNull WorkerParameters workerParams) {
        super(context, workerParams);
    }
    
    @NonNull
    @Override
    public Result doWork() {
        String imagePath = getInputData().getString("imagePath");
        String taskId = getInputData().getString("taskId");
        
        Log.d(TAG, "Iniciando procesamiento de tarea: " + taskId + ", imagen: " + imagePath);
        
        if (imagePath == null || taskId == null) {
            Log.e(TAG, "Datos de entrada inválidos");
            return Result.failure(createErrorOutput(IneProcessorService.ERROR_UNKNOWN, "Datos de entrada inválidos"));
        }
        
        try {
            // Verificar que el archivo existe
            File imageFile = new File(imagePath);
            if (!imageFile.exists()) {
                Log.e(TAG, "Archivo no encontrado: " + imagePath);
                return Result.failure(createErrorOutput(IneProcessorService.ERROR_FILE_NOT_FOUND, "Archivo no encontrado: " + imagePath));
            }
            
            // Verificar que es un archivo de imagen válido
            if (!isValidImageFile(imageFile)) {
                Log.e(TAG, "Archivo de imagen inválido: " + imagePath);
                return Result.failure(createErrorOutput(IneProcessorService.ERROR_INVALID_IMAGE, "Archivo de imagen inválido"));
            }
            
            // Reportar progreso inicial
            setProgressAsync(createProgressData(10, "Validando imagen..."));
            
            // Verificar si es una credencial INE válida
            if (!IneNativeProcessor.isValidIneCredential(imagePath)) {
                Log.w(TAG, "La imagen no parece ser una credencial INE válida");
                // Continuar procesamiento pero marcar como advertencia
            }
            
            // Reportar progreso
            setProgressAsync(createProgressData(30, "Extrayendo texto..."));
            
            // Procesar la credencial
            CredentialResult result = IneNativeProcessor.processCredential(imagePath);
            
            if (result == null) {
                Log.e(TAG, "El procesamiento no devolvió resultados");
                return Result.failure(createErrorOutput(IneProcessorService.ERROR_PROCESSING_FAILED, "El procesamiento no devolvió resultados"));
            }
            
            // Reportar progreso final
            setProgressAsync(createProgressData(100, "Procesamiento completado"));
            
            Log.d(TAG, "Procesamiento completado exitosamente para tarea: " + taskId);
            
            // Crear datos de salida
            Data outputData = new Data.Builder()
                .putString("result", result.toJson())
                .putString("taskId", taskId)
                .build();
            
            return Result.success(outputData);
            
        } catch (Exception e) {
            Log.e(TAG, "Error durante el procesamiento", e);
            return Result.failure(createErrorOutput(IneProcessorService.ERROR_PROCESSING_FAILED, "Error durante el procesamiento: " + e.getMessage()));
        }
    }
    
    /**
     * Crea datos de progreso para reportar al callback
     */
    private Data createProgressData(int progress, String status) {
        return new Data.Builder()
            .putInt("progress", progress)
            .putString("status", status)
            .build();
    }
    
    /**
     * Crea datos de error para el resultado fallido
     */
    private Data createErrorOutput(int errorCode, String errorMessage) {
        return new Data.Builder()
            .putInt("errorCode", errorCode)
            .putString("error", errorMessage)
            .build();
    }
    
    /**
     * Verifica si un archivo es una imagen válida
     */
    private boolean isValidImageFile(File file) {
        if (!file.exists() || !file.isFile()) {
            return false;
        }
        
        String fileName = file.getName().toLowerCase();
        return fileName.endsWith(".jpg") || 
               fileName.endsWith(".jpeg") || 
               fileName.endsWith(".png") || 
               fileName.endsWith(".bmp");
    }
}