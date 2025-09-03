package mx.d3c.dev.ine;

import mx.d3c.dev.ine.IIneProcessorCallback;
import mx.d3c.dev.ine.CredentialResult;

/**
 * AIDL interface para el servicio de procesamiento de credenciales INE
 * Este servicio permite procesar imágenes de credenciales INE mexicanas
 * y extraer información estructurada de las mismas
 */
interface IIneProcessorService {
    /**
     * Procesa una imagen de credencial INE de forma asíncrona
     * @param imagePath Ruta absoluta de la imagen a procesar
     * @param callback Callback para recibir el resultado del procesamiento
     * @return ID único de la tarea de procesamiento
     */
    String processCredentialAsync(String imagePath, IIneProcessorCallback callback);
    
    /**
     * Procesa una imagen de credencial INE de forma síncrona
     * @param imagePath Ruta absoluta de la imagen a procesar
     * @return Resultado del procesamiento en formato JSON
     */
    String processCredentialSync(String imagePath);
    
    /**
     * Verifica si una imagen contiene una credencial INE válida
     * @param imagePath Ruta absoluta de la imagen a verificar
     * @return true si la imagen contiene una credencial INE
     */
    boolean isValidIneCredential(String imagePath);
    
    /**
     * Cancela una tarea de procesamiento en curso
     * @param taskId ID de la tarea a cancelar
     * @return true si la tarea fue cancelada exitosamente
     */
    boolean cancelProcessing(String taskId);
    
    /**
     * Obtiene el estado de una tarea de procesamiento
     * @param taskId ID de la tarea
     * @return Estado de la tarea (PENDING, PROCESSING, COMPLETED, FAILED, CANCELLED)
     */
    String getTaskStatus(String taskId);
    
    /**
     * Obtiene información sobre las capacidades del servicio
     * @return JSON con información de versión y capacidades soportadas
     */
    String getServiceInfo();
}